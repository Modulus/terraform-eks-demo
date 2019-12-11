variable "instance_types" {
    default = ["t3.medium"]
    type = list(string)
}

variable "cluster_name" {
    default = ""
    type = string
}

variable "vpc_id" {
    default = ""
    type = string
}

variable "subnet_ids" {
    default = []
    type = list(string)
}

variable "enable_fargate" {
    default = false
    type = bool
}

variable "fargate_namespaces" {
    default = []
    type = list(string)
}