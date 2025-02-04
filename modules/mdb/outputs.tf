output "db_hostname" {
  value = yandex_mdb_mysql_cluster.mysql-alb-logging.host[0].fqdn
}

output "db_name" {
  value = yandex_mdb_mysql_database.mysql-alb-logging-db.name
}

output "db_user" {
  value = yandex_mdb_mysql_user.mysql_user.name
}

output "db_password" {
  value = yandex_mdb_mysql_user.mysql_user.password
}