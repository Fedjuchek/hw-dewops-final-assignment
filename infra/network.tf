locals {
  public_subnetworks_eks_tags = tomap({
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = 1
  })
  private_subnetworks_eks_tags = tomap({
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = 1
  })
}

# Create a new VPC for EKS cluster
resource "aws_vpc" "hw_eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "hw eks vpc"
  }
}

# Create 4 subnets within 2 AZ in the VPC
resource "aws_subnet" "eks_vpc_subnet_public_a" {
  vpc_id                  = aws_vpc.hw_eks_vpc.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.public_subnetworks_eks_tags, tomap({"Name" = "sn-public-${data.aws_availability_zones.available.names[0]}"}))
}

resource "aws_subnet" "eks_vpc_subnet_private_a" {
  vpc_id            = aws_vpc.hw_eks_vpc.id
  cidr_block        = "10.0.128.0/20"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(local.private_subnetworks_eks_tags, tomap({"Name" = "sn-private-${data.aws_availability_zones.available.names[0]}"}))
}

resource "aws_subnet" "eks_vpc_subnet_public_b" {
  vpc_id            = aws_vpc.hw_eks_vpc.id
  cidr_block        = "10.0.16.0/20"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(local.public_subnetworks_eks_tags, tomap({"Name" = "sn-public-${data.aws_availability_zones.available.names[1]}"}))
}

resource "aws_subnet" "eks_vpc_subnet_private_b" {
  vpc_id            = aws_vpc.hw_eks_vpc.id
  cidr_block        = "10.0.144.0/20"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(local.private_subnetworks_eks_tags, tomap({"Name" = "sn-private-${data.aws_availability_zones.available.names[1]}"}))
}


# Create an Internet Gateway (IGW) and attach it to the VPC
resource "aws_internet_gateway" "eks_vpc_igw" {
  vpc_id = aws_vpc.hw_eks_vpc.id
}

# Create EIP and NAT Gateway
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "eks_vpc_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.eks_vpc_subnet_public_a.id
  depends_on = [
    aws_internet_gateway.eks_vpc_igw
  ]
}

# Create a route table for the VPC and add a route to the IGW
resource "aws_route_table" "eks_vpc_route_table_public" {
  vpc_id = aws_vpc.hw_eks_vpc.id

  tags = {
    Name = "public rt"
  }
}

# Create a route table for the VPC and add a route to the IGW
resource "aws_route_table" "eks_vpc_route_table_private" {
  vpc_id = aws_vpc.hw_eks_vpc.id

  tags = {
    Name = "private rt"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.eks_vpc_route_table_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_vpc_igw.id
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.eks_vpc_route_table_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.eks_vpc_nat.id
}

# Associate public subnet a with the public route table
resource "aws_route_table_association" "eks_vpc_route_table_assoc_public_a" {
  subnet_id      = aws_subnet.eks_vpc_subnet_public_a.id
  route_table_id = aws_route_table.eks_vpc_route_table_public.id
}

# Associate public subnet a with the public route table
resource "aws_route_table_association" "eks_vpc_route_table_assoc_public_b" {
  subnet_id      = aws_subnet.eks_vpc_subnet_public_b.id
  route_table_id = aws_route_table.eks_vpc_route_table_public.id
}

# Associate private subnet b with the private route table
resource "aws_route_table_association" "eks_vpc_route_table_assoc_private_a" {
  subnet_id      = aws_subnet.eks_vpc_subnet_private_a.id
  route_table_id = aws_route_table.eks_vpc_route_table_private.id
}

# Associate private subnet b with the private route table
resource "aws_route_table_association" "eks_vpc_route_table_assoc_private_b" {
  subnet_id      = aws_subnet.eks_vpc_subnet_private_b.id
  route_table_id = aws_route_table.eks_vpc_route_table_private.id
}
