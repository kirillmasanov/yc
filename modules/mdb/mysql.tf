locals {
  mysql_version   = "8.0"
  resource_preset = "s2.micro" # 2 vCPU, 8 GB RAM
  disk_type       = "network-ssd"
  disk_size       = 16 # GB
  db_name         = "test-db"
  user            = "john"
  password        = "password"
}

resource "yandex_mdb_mysql_cluster" "mysql-alb-logging" {
  name               = "test"
  environment        = "PRESTABLE"
  network_id         = var.network_id
  version            = local.mysql_version
  security_group_ids = [yandex_vpc_security_group.mysql-security-group.id]

  resources {
    resource_preset_id = local.resource_preset
    disk_type_id       = local.disk_type
    disk_size          = local.disk_size
  }

  mysql_config = {
    sql_mode                      = "ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
    max_connections               = 100
    default_authentication_plugin = "MYSQL_NATIVE_PASSWORD"
    innodb_print_all_deadlocks    = true

  }

  access {
    web_sql = true
  }

  host {
    zone             = var.zone
    subnet_id        = var.subnet_a_id
    assign_public_ip = true
  }
}

resource "yandex_mdb_mysql_database" "mysql-alb-logging-db" {
  cluster_id = yandex_mdb_mysql_cluster.mysql-alb-logging.id
  name       = local.db_name
}

resource "yandex_mdb_mysql_user" "mysql_user" {
  cluster_id = yandex_mdb_mysql_cluster.mysql-alb-logging.id
  name       = local.user
  password   = local.password

  permission {
    database_name = yandex_mdb_mysql_database.mysql-alb-logging-db.name
    roles         = ["ALL"]
  }

  connection_limits {
    max_questions_per_hour   = 1000
    max_updates_per_hour     = 2000
    max_connections_per_hour = 300
    max_user_connections     = 40
  }

  global_permissions = ["PROCESS"]

  authentication_plugin = "SHA256_PASSWORD"

  lifecycle {
    ignore_changes = [password]
  }
}

resource "null_resource" "mysql_create_table" {
  provisioner "local-exec" {
    environment = {
      MYSQL_PWD = "${local.password}"
    }
    command = <<EOT
      mysql --host=${yandex_mdb_mysql_cluster.mysql-alb-logging.host[0].fqdn} \
      --port=3306 \
      --ssl-ca=./modules/mdb/root.crt \
      --ssl-mode=VERIFY_IDENTITY \
      --user=${local.user} -D ${local.db_name} < ./modules/mdb/mysql.sql
    EOT
  }
  depends_on = [yandex_mdb_mysql_user.mysql_user]
}

resource "yandex_vpc_security_group" "mysql-security-group" {
  description = "Security group for the Managed Service for MySQL"
  name        = "mysql-security-group"
  network_id  = var.network_id

  ingress {
    description    = "Allow connections to the Managed Service for MySQL cluster from the Internet"
    protocol       = "TCP"
    port           = 3306
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "The rule allows all outgoing traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
