locals {
    vpc_cidr = "172.22.80.0/21"
    private_subnets = ["172.22.80.0/24", "172.22.81.0/24", "172.22.82.0/24"]
    public_subnets = ["172.22.83.0/24", "172.22.84.0/24", "172.22.85.0/24"]

    region = "eu-west-1"
    azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

    cluster_name = "fargate-test"

}

provider "aws" {
  version = "~> 2.0"
  region  = local.region
}
 

module "network" {
    source = "./modules/network"

    vpc_cidr_block = local.vpc_cidr
    private_subnets = local.private_subnets
    public_subnets = local.public_subnets
    name = "fargate-test"
    managed_by = "tv2i"
    azs = local.azs
    tags = {
        "kubernetes.io/cluster/${local.cluster_name}" = "shared"
        purpose = "test"
    }

    subnet_tags = {
        "kubernetes.io/cluster/${local.cluster_name}" = "shared"
        purpose = "test"
    }
}

module "blue_cluster" {
    source = "./modules/eks"
    cluster_name = local.cluster_name
    vpc_id = module.network.vpc_id

    subnet_ids = module.network.private_subnet_ids
    enable_fargate = true
    fargate_namespaces = ["demo"]
}

output "private_subnet_ids" {
    value = module.network.private_subnet_ids
}

output "public_subnet_ids" {
    value = module.network.public_subnet_ids
}

output "vpc_id" {
    value = module.network.vpc_id
}

output "blue_id" {
    value = module.blue_cluster.id
}

output "blue_node_groups" {
    value = module.blue_cluster.node_groups
}

output "blue_status" {
    value = module.blue_cluster.status
}