locals {
  namespace_name = "my-app-namespace"
}

resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = <<EOT
      docker build --platform=linux/amd64 -t cr.yandex/${var.container_repository_name}:latest -f ./modules/app/Dockerfile ./modules/app/
      docker push cr.yandex/${var.container_repository_name}:latest
    EOT
  }
}

resource "kubernetes_namespace" "my-app-namespace" {
  metadata {
    name = local.namespace_name
  }
}

resource "kubernetes_deployment" "flask_app" {
  metadata {
    name      = "flask-app"
    namespace = kubernetes_namespace.my-app-namespace.metadata[0].name
    labels = {
      app = "flask-app"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "flask-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "flask-app"
        }
      }

      spec {
        container {
          image = "cr.yandex/${var.container_repository_name}:latest"
          name  = "flask-app"

          env {
            name  = "DB_HOST"
            value = var.db_hostname
          }

          env {
            name  = "DB_USER"
            value = var.db_user
          }

          env {
            name  = "DB_PASSWORD"
            value = var.db_password
          }

          env {
            name  = "DB_NAME"
            value = var.db_name
          }

          env {
            name  = "SSL_CA_PATH"
            value = "/certs/root.crt"
          }

          env {
            name = "NODE_IP"
            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          volume_mount {
            name       = "mysql-cert-volume"
            mount_path = "/certs"
            read_only  = true
          }

          port {
            container_port = 8080
          }
        }

        volume {
          name = "mysql-cert-volume"
          secret {
            secret_name = kubernetes_secret.mysql_cert.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret.mysql_cert,
    null_resource.docker_push
  ]
}

resource "kubernetes_secret" "mysql_cert" {
  metadata {
    name      = "mysql-cert"
    namespace = kubernetes_namespace.my-app-namespace.metadata[0].name
  }

  data = {
    "root.crt" = file("./modules/app/root.crt")
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.my-app-namespace]
}

resource "kubernetes_service" "default-service" {
  metadata {
    name      = "default-service"
    namespace = kubernetes_namespace.my-app-namespace.metadata[0].name
  }
  spec {
    selector = {
      app = "flask-app"
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "NodePort"
  }
  depends_on = [kubernetes_deployment.flask_app]
}

resource "kubernetes_service" "app1-service" {
  metadata {
    name      = "app1-service"
    namespace = kubernetes_namespace.my-app-namespace.metadata[0].name
  }
  spec {
    selector = {
      app = "flask-app"
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "NodePort"
  }
  depends_on = [kubernetes_deployment.flask_app]
}

resource "kubernetes_service" "app2-service" {
  metadata {
    name      = "app2-service"
    namespace = kubernetes_namespace.my-app-namespace.metadata[0].name
  }
  spec {
    selector = {
      app = "flask-app"
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "NodePort"
  }
  depends_on = [kubernetes_deployment.flask_app]
}
