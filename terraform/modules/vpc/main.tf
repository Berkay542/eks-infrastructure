resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                     = "${var.env}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}


resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.env}-nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "${var.env}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}


resource "aws_subnet" "public_subnets" {
  vpc_id                          = aws_vpc.main.id
  count                           = length(var.public_subnet_cidrs)
  cidr_block                      = element(var.public_subnet_cidrs, count.index)
  map_public_ip_on_launch         = true 
  availability_zone               = element(var.availability_zones, count.index)

  tags = {
    Name                                               = "${var.env}-Public Subnet ${count.index + 1}"
    "kubernetes.io/role/elb"                           = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
    
  }
}


resource "aws_subnet" "private_subnets" {
 count                           = length(var.private_subnet_cidrs)
 vpc_id                          = aws_vpc.main.id
 cidr_block                      = element(var.private_subnet_cidrs, count.index)
 availability_zone               = element(var.availability_zones, count.index)

  tags = {
    Name                                               = "${var.env}-Private Subnet ${count.index + 1}"
    "kubernetes.io/role/internal-elb"                  = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}



resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.env}-private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env}-public"
  }
}


resource "aws_route_table_association" "public_subnet_asso" {
 count          = length(var.public_subnet_cidrs)
 subnet_id      = aws_subnet.public_subnets[count.index].id
 route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_subnet_asso" {
 count          = length(var.private_subnet_cidrs)
 subnet_id      = aws_subnet.private_subnets[count.index].id
 route_table_id = aws_route_table.private.id
}