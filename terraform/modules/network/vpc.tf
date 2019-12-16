resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  # region = var.region
  // We cannot destroy the VPC, since this would also remove manually created VPC peering connections
  lifecycle {
    prevent_destroy = false
  }
  tags = merge(
    {
    Name       = "${var.name}-vpc-${var.region}"
    managed_by = var.managed_by
    region = var.region
    tool = "terraform"
  }, var.tags
  )
}


resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnets)

  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  map_public_ip_on_launch = false

  tags = merge({
    Name = "${var.name}-private-subnet-${var.azs[count.index]}"
    Type = "private"
    Tool = "terraform"
    az = var.azs[count.index]
  }, var.subnet_tags)

  depends_on = [
    aws_vpc.main_vpc
  ]
}


// Reserves a elastic ip for the the nat gateway
resource "aws_eip" "nat_gw_eip" {
  count = length(var.azs)
  vpc = true
  tags = {
    Name      = "${var.name}-nat_gw-eip-${var.azs[count.index]}"
  }
}

// Put the nat gateway into the first submet
resource "aws_nat_gateway" "nat_gw" {
  count = length(var.azs)
  allocation_id =  element(aws_eip.nat_gw_eip.*.id, count.index)
  subnet_id = element(aws_subnet.public_subnets.*.id, count.index) //"${element(aws_subnet.public-network.*.id,0)}"

  tags = {
    Name       = "${var.name}-nat_gw"
    managed-by = "${var.managed_by}"
  }

  depends_on = [
    aws_subnet.public_subnets
  ]
}


resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name       = "${var.name}-main-igw"
    managed-by = var.managed_by
  }
}


resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnets)

  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.public_subnets[count.index]
  availability_zone = var.azs[count.index]

  map_public_ip_on_launch = true
  tags = merge({
    Name = "${var.name}-private-subnet-${var.azs[count.index]}"
    Type = "public"
    Tool = "terraform"
    az = var.azs[count.index]
  }, var.public_subnet_tags)




  depends_on = [
    aws_vpc.main_vpc
  ]
}



resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  count = length(var.private_subnets)


  route {

    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    name = "${var.name}-route-table-private"
  }

  depends_on = [
    aws_vpc.main_vpc
  ]
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.main_igw.id
    }

  tags = {
    Name       = "${var.name}-public"
    managed_by = var.managed_by
  }
}


resource "aws_route_table_association" "private_route_table_association" {
  count = length(var.private_subnets)

  subnet_id = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
} 

resource "aws_route_table_association" "public_route_table_association" {
  count = length(var.public_subnets)

  subnet_id = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.public_route_table.*.id, count.index)
} 


output "private_subnet_ids" {
  value = aws_subnet.private_subnets.*.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets.*.id
}


output "vpc_id" {
  value = aws_vpc.main_vpc.id
}