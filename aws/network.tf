resource "aws_vpc" "dataplane_vpc" {
  cidr_block           = var.routable_vpc_cidr_range
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${local.prefix}-dataplane-vpc"
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.dataplane_vpc.id
  cidr_block = var.non_routable_vpc_cidr_range
}

// Routable Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.dataplane_vpc.id
  count                   = length(local.routable_public_subnets_cidr)
  cidr_block              = element(local.routable_public_subnets_cidr, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
      Name = "${local.prefix}-public-${element(local.availability_zones, count.index)}"
  }
}


// Routable Private Subnets
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.dataplane_vpc.id
  count                   = length(local.routable_private_subnets_cidr)
  cidr_block              = element(local.routable_private_subnets_cidr, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = false
  tags = {
    Name = "${local.prefix}-private-${element(local.availability_zones, count.index)}"
  }
}

// Non-Routable Private Subnets
resource "aws_subnet" "non_routable" {
  vpc_id                  =  aws_vpc.dataplane_vpc.id
  count                   = length(local.non_routable_private_subnets_cidr)
  cidr_block              = element(local.non_routable_private_subnets_cidr, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = false
  tags = {
    Name = "${local.prefix}-non-routable-private-${element(local.availability_zones, count.index)}"
  }
  depends_on = [aws_vpc_ipv4_cidr_block_association.secondary_cidr]
}

// PrivateLink Subnet
resource "aws_subnet" "privatelink" {
  vpc_id                  = aws_vpc.dataplane_vpc.id
  count                   = length(local.privatelink_subnets_cidr)
  cidr_block              = element(local.privatelink_subnets_cidr, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = false
  tags = {
    Name = "${local.prefix}-privatelink-${element(local.availability_zones, count.index)}"
  }
}

// Dataplane NACL
resource "aws_network_acl" "dataplane" {
  vpc_id = aws_vpc.dataplane_vpc.id
  subnet_ids = concat(aws_subnet.private[*].id, aws_subnet.public[*].id, aws_subnet.non_routable[*].id)

  ingress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
  egress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  dynamic "egress" {
    for_each = local.sg_egress_ports
    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      action      = "ALLOW"
      rule_no     = egress.key + 200
    }
  }
  tags = {
    Name = "${local.prefix}-nacl"
  }
}

// IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dataplane_vpc.id
  tags = {
    Name = "${local.prefix}-igw"
  }
}

// EIP
resource "aws_eip" "ngw_eip" {
  count      = length(local.routable_public_subnets_cidr)
  vpc        = true
}

// NGW
resource "aws_nat_gateway" "ngw" {
  count         = length(local.routable_public_subnets_cidr)
  allocation_id = element(aws_eip.ngw_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "${local.prefix}-ngw-${element(local.availability_zones, count.index)}"
  }
}

// Private NGW
resource "aws_nat_gateway" "private_ngw" {
  connectivity_type = "private"
  count         = length(local.routable_public_subnets_cidr)
  subnet_id         =  element(aws_subnet.private.*.id, count.index)
}

// SG
resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.dataplane_vpc.id
  depends_on  = [aws_vpc.dataplane_vpc]

  dynamic "ingress" {
    for_each = local.sg_ingress_protocol
    content {
      from_port = 0
      to_port   = 65535
      protocol  = ingress.value
      self      = true
    }
  }

  dynamic "egress" {
    for_each = local.sg_egress_protocol
    content {
      from_port = 0
      to_port   = 65535
      protocol  = egress.value
      self      = true
    }
  }

  dynamic "egress" {
    for_each = local.sg_egress_ports
    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  tags = {
    Name = "${local.prefix}-dataplane-sg"
  }
}


// IGW RT
resource "aws_route_table" "igw_rt" {
  vpc_id             = aws_vpc.dataplane_vpc.id
    tags = {
      Name = "${local.prefix}-igw-rt"
  }
}


// Routable Public RT
resource "aws_route_table" "public_rt" {
    count              = length(local.routable_public_subnets_cidr)
    vpc_id            = aws_vpc.dataplane_vpc.id
    tags  = {
      Name = "${local.prefix}-public-rt-${element(local.availability_zones, count.index)}"
  }
}

// Routable Private RT
resource "aws_route_table" "private_rt" {
  count              = length(local.routable_private_subnets_cidr)
  vpc_id             = aws_vpc.dataplane_vpc.id
  tags = {
    Name = "${local.prefix}-private-rt-${element(local.availability_zones, count.index)}"
  }
}

// Non-Routable Private RT
resource "aws_route_table" "non_routable_rt" {
  count              = length(local.non_routable_private_subnets_cidr)
  vpc_id             = aws_vpc.dataplane_vpc.id
  tags = {
    Name = "${local.prefix}-non-routable-private-rt-${element(local.availability_zones, count.index)}"
  }
}

// IGW RT Associations
resource "aws_route_table_association" "igw" {
  gateway_id     = aws_internet_gateway.igw.id
  route_table_id = aws_route_table.igw_rt.id
}

// Routable Public RT Associations
resource "aws_route_table_association" "public" {
  count          = length(local.routable_public_subnets_cidr)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public_rt.*.id, count.index)
  depends_on = [aws_subnet.public]
}

// Routable Private RT Associations
resource "aws_route_table_association" "private" {
  count          = length(local.routable_private_subnets_cidr)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private_rt.*.id, count.index)
}

// Non-Routable Private RT Associations
resource "aws_route_table_association" "non_routable" {
  count          = length(local.non_routable_private_subnets_cidr)
  subnet_id      = element(aws_subnet.non_routable.*.id, count.index)
  route_table_id = element(aws_route_table.non_routable_rt.*.id, count.index)
}

// Routable Public Route
resource "aws_route" "public" {
  count                  = length(local.routable_public_subnets_cidr)
  route_table_id         = element(aws_route_table.public_rt.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             =  aws_internet_gateway.igw.id 
  depends_on             =  [aws_internet_gateway.igw]
}

// Routable Private Route
resource "aws_route" "private" {
  count                  = length(local.routable_private_subnets_cidr)
  route_table_id         = element(aws_route_table.private_rt.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.ngw.*.id, count.index)
}

// Non Routable Private Route
resource "aws_route" "non_routable" {
  count                  = length(local.non_routable_private_subnets_cidr)
  route_table_id         = element(aws_route_table.non_routable_rt.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.private_ngw.*.id, count.index)
}