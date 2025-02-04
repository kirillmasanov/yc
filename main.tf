module "network" {
  source = "./modules/network"

  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

module "mdb" {
  source = "./modules/mdb"

  folder_id   = var.folder_id
  network_id  = module.network.network_id
  subnet_a_id = module.network.subnet_id["a"]
  zone        = var.zone

  depends_on = [module.network]
}

module "k8s" {
  source = "./modules/k8s"

  cloud_id           = var.cloud_id
  folder_id          = var.folder_id
  network_id         = module.network.network_id
  subnet_id          = module.network.subnet_id
  vpc_subnet_default = module.network.vpc_subnet_default

  depends_on = [module.mdb]
}

module "alb-ingress" {
  source = "./modules/alb-ingress"

  folder_id             = var.folder_id
  dns                   = var.dns
  network_id            = module.network.network_id
  subnet_cidr           = module.network.subnet_cidr
  subnet_id             = module.network.subnet_id
  cluster_id            = module.k8s.cluster_id
  external_ipv4_address = module.dns.external_ipv4_address
  # cert_id = module.dns.cert_id

  depends_on = [module.k8s]
}

module "function" {
  source = "./modules/function"

  folder_id        = var.folder_id
  db_hostname      = module.mdb.db_hostname
  db_name          = module.mdb.db_name
  db_user          = module.mdb.db_user
  db_password      = module.mdb.db_password
  alb_log_group_id = module.k8s.alb_log_group_id

  depends_on = [module.alb-ingress]
}

module "dns" {
  source = "./modules/dns"

  dns  = var.dns
  zone = var.zone
}

module "registry" {
  source = "./modules/registry"

  folder_id = var.folder_id

  depends_on = [module.mdb]
}

module "app" {
  source = "./modules/app"

  db_hostname               = module.mdb.db_hostname
  db_name                   = module.mdb.db_name
  db_user                   = module.mdb.db_user
  db_password               = module.mdb.db_password
  container_repository_name = module.registry.container_repository_name

  depends_on = [module.k8s, module.registry, module.mdb]
}
