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

    instance_types = ["t3.medium"]
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

resource "aws_lb_target_group" "active_ingress_target_group" {
  name = "active-ingress-target-group"
  port = 30080
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = module.network.vpc_id

  health_check  {
    path    = "/nginx-health"
    matcher = "200-299"
    port    = 30080
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "alb_listener_all" {
  load_balancer_arn = module.alb.arn
  port              = "80"
#   ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2019-08" #"ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn = "arn:aws:acm:eu-north-1:417643524488:certificate/a3a8a326-40e9-4f34-b323-644c3cafd977"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.active_ingress_target_group.arn

    #target_group_arn = local.active == "blue" ? aws_lb_target_group.ingress_target_group.arn : aws_lb_target_group.ingress_target_group_green.arn
    type             = "forward"
  }
}


# resource "aws_lb_listener_rule" "active_lb_listener_rule" {

#   # Should forward to green target group if active is set to blue
#   listener_arn = aws_alb_listener.alb_listener_all.arn
#   action {
#     type = "forward"
#     #target_group_arn = local.active == "blue" ? aws_lb_target_group.ingress_target_group_green.arn : aws_lb_target_group.ingress_target_group.arn
#     target_group_arn = aws_lb_target_group.active_ingress_target_group.arn

#   }

#   condition {
#     field = "host-header"
#     values = ["*.example.no"]
#   }
# }

resource "aws_autoscaling_attachment" "blue_attachement" {
    count = length(module.blue_cluster.resources[0].autoscaling_groups)

    autoscaling_group_name = module.blue_cluster.resources[0].autoscaling_groups[count.index].name

    alb_target_group_arn = aws_lb_target_group.active_ingress_target_group.arn
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