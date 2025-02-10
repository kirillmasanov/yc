resource "yandex_iam_service_account" "k8s_cluster_alb" {
  folder_id   = var.folder_id
  description = "Service account for k8s cluster ALB Ingress Controller"
  name        = "k8s-cluster-alb-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_alb_roles" {
  folder_id = var.folder_id

  for_each = toset([
    "alb.editor",                                  # alb.editor — для создания необходимых ресурсов.
    "vpc.publicAdmin",                             # для управления внешней связностью.
    "certificate-manager.certificates.downloader", # для работы с сертификатами, зарегистрированными в сервисе Yandex Certificate Manager.
    "compute.viewer",                              # для использования узлов кластера Managed Service for Kubernetes в целевых группах балансировщика.
  ])
  role   = each.value
  member = "serviceAccount:${yandex_iam_service_account.k8s_cluster_alb.id}"
  depends_on = [
    yandex_iam_service_account.k8s_cluster_alb,
  ]
  sleep_after = 5
}

resource "yandex_iam_service_account_key" "k8s_cluster_alb" {
  service_account_id = yandex_iam_service_account.k8s_cluster_alb.id
  depends_on = [
    yandex_iam_service_account.k8s_cluster_alb,
  ]
}

resource "kubernetes_namespace" "alb_ingress" {
  metadata {
    name = "alb-ingress"
  }
}

locals {
  sa_key = jsonencode({
    id                 = yandex_iam_service_account_key.k8s_cluster_alb.id
    service_account_id = yandex_iam_service_account_key.k8s_cluster_alb.service_account_id
    created_at         = yandex_iam_service_account_key.k8s_cluster_alb.created_at
    key_algorithm      = yandex_iam_service_account_key.k8s_cluster_alb.key_algorithm
    public_key         = yandex_iam_service_account_key.k8s_cluster_alb.public_key
    private_key        = yandex_iam_service_account_key.k8s_cluster_alb.private_key
  })
}

resource "kubernetes_secret" "yc_alb_ingress_controller_sa_key" {
  metadata {
    name      = "yc-alb-ingress-controller-sa-key"
    namespace = "alb-ingress"
  }
  data = {
    "sa-key.json" = local.sa_key
  }
  type = "kubernetes.io/Opaque"

  depends_on = [kubernetes_namespace.alb_ingress]
}

resource "helm_release" "alb_ingress" {
  name             = "alb-ingress"
  namespace        = "alb-ingress"
  repository       = "oci://cr.yandex/yc-marketplace/yandex-cloud/yc-alb-ingress"
  chart            = "yc-alb-ingress-controller-chart"
  version          = "v0.2.17"
  create_namespace = true

  set {
    name  = "folderId"
    value = var.folder_id
  }

  set {
    name  = "clusterId"
    value = var.cluster_id
  }

  set {
    name  = "daemonsetTolerations[0].operator"
    value = "Exists"
  }

  set_sensitive {
    name  = "auth.json"
    value = local.sa_key
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_cluster_alb_roles,
    yandex_iam_service_account_key.k8s_cluster_alb,
    kubernetes_namespace.alb_ingress,
    kubernetes_secret.yc_alb_ingress_controller_sa_key,
  ]
}


resource "yandex_vpc_security_group" "alb" {
  name        = "k8s-alb"
  description = "alb security group"
  network_id  = var.network_id
  folder_id   = var.folder_id

  ingress {
    protocol       = "ICMP"
    description    = "ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "https"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule allows availability checks from load balancer's address range. It is required for a db cluster"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol          = "ANY"
    description       = "Rule allows master and slave communication inside a security group."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  egress {
    protocol       = "TCP"
    description    = "Enable traffic from ALB to K8s services"
    v4_cidr_blocks = flatten(values(var.subnet_cidr))
    from_port      = 30000
    to_port        = 65535
  }

  egress {
    protocol       = "TCP"
    description    = "Enable probes from ALB to K8s"
    v4_cidr_blocks = flatten(values(var.subnet_cidr))
    port           = 10501
  }
}

resource "kubernetes_ingress_v1" "flask_ingress" {
  metadata {
    name      = "flask-ingress"
    namespace = "my-app-namespace"
    annotations = {
      "ingress.alb.yc.io/subnets"               = join(",", flatten([for subnet in var.subnet_id : subnet]))
      "ingress.alb.yc.io/security-groups"       = yandex_vpc_security_group.alb.id
      "ingress.alb.yc.io/external-ipv4-address" = var.external_ipv4_address
      "ingress.alb.yc.io/group-name"            = "flask-app-group"
    }
  }

  spec {
    # tls {
    #   hosts = [var.dns]
    #   secret_name = "yc-certmgr-cert-id-${var.cert_id}"
    # }
    rule {
      host = var.dns
      http {
        path {
          path      = "/page1.html"
          path_type = "Prefix"
          backend {
            service {
              name = "app1-service"
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/page2.html"
          path_type = "Prefix"
          backend {
            service {
              name = "app2-service"
              port {
                number = 80
              }
            }
          }
        }
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "default-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.alb_ingress]
}
