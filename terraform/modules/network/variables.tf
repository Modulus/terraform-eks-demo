variable "vpc_cidr_block" {
  type        = string
  description = "Cidr block for VPC"
}


variable "private_subnets" {
   default = []
   description = "List of cidr block for private subnets"
}

variable "public_subnets" {
   default = []
   description = "List of cidr block for public subnets"
}

# variable "region" {
#   default = "FILL INN"
#   description = "What region should the network be created in"
# }

variable "route53_public_zone_id" {
  default = ""
  description = "Public DNS zone for registering of public LB"
}

variable "name" {
  default = ""
  description = "Name of this vpc"
}

variable "managed_by" {
  default = "chief"
  description = "Who is managing this network"
}


variable "region" {
  default = "eu-west-1"
  description = "Region for this network"
}

variable "azs" {
  default = []
  description = "List of availability zones to place the subnets"
}


variable "tags" {
  default = {

  }
}

variable "subnet_tags" {
  default = {
    
  }
}


variable "public_subnet_tags" {
  default = {
    
  }
}
