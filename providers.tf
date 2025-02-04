terraform {
  backend "local" {
    path = "./state/terraform.tfstate"
  }
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.35.1"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

data "yandex_client_config" "client" {}

provider "helm" {
  debug = true
  kubernetes {
    host                   = module.k8s.external_v4_endpoint
    cluster_ca_certificate = module.k8s.cluster_ca_certificate
    token                  = data.yandex_client_config.client.iam_token
  }
  registry {
    url      = "oci://cr.yandex"
    username = "iam"
    password = data.yandex_client_config.client.iam_token
  }
}

provider "kubernetes" {
  host                   = module.k8s.external_v4_endpoint
  cluster_ca_certificate = module.k8s.cluster_ca_certificate
  token                  = data.yandex_client_config.client.iam_token
}
