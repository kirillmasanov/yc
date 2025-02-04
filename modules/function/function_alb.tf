resource "yandex_iam_service_account" "alb-logging-sa" {
  name        = "alb-logging-service-account"
  description = "service account for function"
  folder_id   = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "alb-logging-sa-editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.alb-logging-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "alb-logging-sa-invoker" {
  folder_id = var.folder_id
  role      = "functions.functionInvoker"
  member    = "serviceAccount:${yandex_iam_service_account.alb-logging-sa.id}"
}

resource "yandex_function" "alb-logging-function" {
  name               = "alb-logging-function"
  description        = "Logging function"
  user_hash          = "first-function"
  runtime            = "python312"
  entrypoint         = "alb_logging_function.handler"
  memory             = "128"
  execution_timeout  = "10"
  service_account_id = yandex_iam_service_account.alb-logging-sa.id
  environment = {
    VERBOSE_LOG = "True"
    DB_HOSTNAME = var.db_hostname
    DB_PORT     = "3306"
    DB_NAME = var.db_name
    DB_USER = var.db_user
    DB_PASSWORD = var.db_password
    DB_SSL_CA   = "root.crt"
  }

  content {
    zip_filename = "./modules/function/function/function.zip"
  }
}

resource "yandex_function_trigger" "alb-logging-trigger" {
  name      = "alb-logging-trigger"
  folder_id = var.folder_id

  function {
    id                 = yandex_function.alb-logging-function.id
    service_account_id = yandex_iam_service_account.alb-logging-sa.id
    tag                = "$latest"

  }
  logging {
    group_id       = var.alb_log_group_id
    resource_types = ["alb.loadBalancer"]
    batch_cutoff   = "15"
    batch_size     = "10"
  }
}
