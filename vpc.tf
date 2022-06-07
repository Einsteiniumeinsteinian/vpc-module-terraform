resource "aws_vpc" "vpc" {
  cidr_block           = var.network.cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    name : "${var.tags.name}-vpc"
    environment : var.tags.environment
  }
}

#internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    name        = "${var.tags.name}-igw"
    environment = var.tags.environment
  }
}

# elastic Ip
resource "aws_eip" "eip" {
  count = var.network.private_subnet == null || var.network.nat_gateway == false ? 0 : length(var.network.private_subnet)

  tags = {
    name = "${var.tags.name}-eip${count.index}"
    environment : var.tags.environment
  }
}

# nat id
resource "aws_nat_gateway" "nat" {
  count         = var.network.nat_gateway == false || aws_eip.eip == null ? 0 : length(var.network.private_subnet)
  subnet_id     = aws_subnet.public_subnet[count.index].id
  connectivity_type = "public"
  allocation_id = aws_eip.eip[count.index].id
  depends_on = [
    aws_internet_gateway.igw
  ]
  tags = {
    name = "${var.tags.name}-nat"
    environment : var.tags.environment
  }
}

#Private subnet
resource "aws_subnet" "private_subnet" {
  count                   = var.network.private_subnet == null ? 0 : length(var.network.private_subnet)
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = element(var.network.Azs, count.index)
  cidr_block              = element(var.network.private_subnet, count.index)
  map_public_ip_on_launch = false

  tags = {
    name = "${var.tags.name}_private_subnet${count.index}"
    environment : var.tags.environment
  }
}

#Private Route table and Route Table Association
resource "aws_route_table" "private_rtb" {
  count = length(var.network.Azs)
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    name = "${var.tags.name}-private-rtb"
    environment : var.tags.environment
  }
}

#Private Route Table Association
resource "aws_route_table_association" "private_rtba" {
  count          = var.network.private_subnet == null ? 0 : length(var.network.private_subnet)
  route_table_id = aws_route_table.private_rtb[count.index].id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}

#Public subnet
resource "aws_subnet" "public_subnet" {
  count                   = var.network.public_subnet == null ? 0 : length(var.network.public_subnet)
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = element(var.network.Azs, count.index)
  cidr_block              = element(var.network.public_subnet, count.index)
  map_public_ip_on_launch = true

  tags = {
    name = "${var.tags.name}_public_subnet${count.index}"
    environment : var.tags.environment
  }
}

#Public Route table
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    name = "${var.tags.name}-public-rtb"
    environment : var.tags.environment
  }
}

# Public Route Table Association
resource "aws_route_table_association" "public_rtba" {
  count          = length(var.network.public_subnet)
  route_table_id = aws_route_table.public_rtb.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}


# Secuirty Group
locals {
  ports_in = [22, 443, 80]
  #   port_out = [0]
}

resource "aws_security_group" "sg" {
  name        = "${var.tags.name}_sg"
  description = "Allow inbound traffic for sales vpc"
  vpc_id      = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc
  ]

  dynamic "ingress" {
    for_each = local.ports_in
    content {
      description = "allow port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["105.112.28.161/32"]
      self        = true
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    self             = true
  }

  tags = {
    "Name" = "${var.tags.name}_sg"
  }
}

