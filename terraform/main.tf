locals {

    vpc_cidr = "10.168.192.0/18"
    private_subnets = ["10.168.192.0/20", "10.168.208.0/20", "10.168.224.0/20"]
    public_subnets = ["10.168.240.0/22", "10.168.244.0/22", "10.168.248.0/22"]

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
    managed_by = "sjefen"
    azs = local.azs
    tags = {
        "kubernetes.io/cluster/${local.cluster_name}-blue" = "shared"
        purpose = "test"
    }

    subnet_tags = {
        "kubernetes.io/cluster/${local.cluster_name}-blue" = "shared"
        purpose = "test"
        "kubernetes.io/role/internal-elb" = 1
    }

    public_subnet_tags = {
        "kubernetes.io/cluster/${local.cluster_name}-blue" = "shared"
        purpose = "test"
        "kubernetes.io/role/elb" = 1
    }
}

module "blue_cluster" {
    source = "./modules/eks"
    cluster_name = "${local.cluster_name}-blue"
    vpc_id = module.network.vpc_id

    subnet_ids = module.network.private_subnet_ids
    enable_fargate = true
    fargate_namespaces = ["demo"]
}

# module "green_cluster" {
#     source = "./modules/eks"
#     cluster_name = "${local.cluster_name}-green"
#     vpc_id = module.network.vpc_id

#     subnet_ids = module.network.private_subnet_ids
#     enable_fargate = true
#     fargate_namespaces = ["demo"]
# }

module "alb" {
    source = "./modules/loadbalancer"
    name = "${local.cluster_name}-alb"

    subnet_ids = module.network.public_subnet_ids

    security_group_ids = []

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


# output "green_id" {
#     value = module.green_cluster.id
# }

# output "green_node_groups" {
#     value = module.green_cluster.node_groups
# }

# output "green_status" {
#     value = module.green_cluster.status
# }