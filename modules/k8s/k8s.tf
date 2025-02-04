resource "yandex_kubernetes_cluster" "k8s_cluster" {
  name        = "my-k8s-cluster"
  description = "My k8s cluster"

  network_id = var.network_id

  master {
    version = var.master_version
    regional {
      region = "ru-central1"

      location {
        zone      = var.vpc_subnet_default["a"].zone
        subnet_id = var.subnet_id["a"]
      }

      location {
        zone      = var.vpc_subnet_default["b"].zone
        subnet_id = var.subnet_id["b"]
      }

      location {
        zone      = var.vpc_subnet_default["d"].zone
        subnet_id = var.subnet_id["d"]
      }
    }

    public_ip = true

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        start_time = "15:00"
        duration   = "3h"
      }
    }

    master_logging {
      enabled                    = true
      log_group_id               = yandex_logging_group.k8s_log_group.id
      kube_apiserver_enabled     = true
      cluster_autoscaler_enabled = true
      events_enabled             = true
      audit_enabled              = true
    }
  }

  service_account_id      = yandex_iam_service_account.master_sa.id
  node_service_account_id = yandex_iam_service_account.node_sa.id

  release_channel = "RAPID"
  network_implementation {
    cilium {}
  }
  kms_provider {
    key_id = yandex_kms_symmetric_key.kms_key.id
  }
  depends_on = [
    yandex_resourcemanager_folder_iam_member.master_sa_roles,
  ]
}

resource "yandex_kubernetes_node_group" "dz_node_group" {
  cluster_id  = yandex_kubernetes_cluster.k8s_cluster.id
  name        = "default-nodes"
  description = "K8s Cluster Nodes"
  version     = var.nodes_version

  instance_template {
    platform_id = var.node_groups_defaults.platform_id

    network_interface {
      ipv4       = var.node_groups_defaults.ipv4
      nat        = var.node_groups_defaults.nat
      subnet_ids = [for subnet in var.vpc_subnet_default : subnet.id]
    }

    resources {
      memory        = var.node_groups_defaults.node_memory
      cores         = var.node_groups_defaults.node_cores
      core_fraction = var.node_groups_defaults.core_fraction
    }

    boot_disk {
      type = var.node_groups_defaults.disk_type
      size = var.node_groups_defaults.disk_size
    }

    scheduling_policy {
      preemptible = var.node_groups_defaults.preemptible
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale {
      size = var.node_groups_defaults.size
    }
  }

  allocation_policy {
    dynamic "location" {
      for_each = var.vpc_subnet_default
      content {
        zone = location.value.zone
      }
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "15:00"
      duration   = "3h"
    }

    maintenance_window {
      day        = "friday"
      start_time = "10:00"
      duration   = "4h30m"
    }
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.node_sa_roles,
  ]
}
