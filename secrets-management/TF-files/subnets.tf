# Resource: aws_subnet
resource "aws_subnet" "public_1" {
  vpc_id = aws_vpc.secret_vpc.id
  cidr_block = "192.168.0.0/18"

  # The AZ for the subnet.
  availability_zone = var.pub1_az

  # Required for EKS. Instances launched into the subnet should be assigned a public IP address.
  map_public_ip_on_launch = true
  tags = {
    Name                        = "public-us-east-2a"
    "kubernetes.io/cluster/eks" = "shared"
    "kubernetes.io/role/elb"    = 1
  }
}

resource "aws_subnet" "public_2" {
  vpc_id = aws_vpc.secret_vpc.id
  cidr_block = "192.168.64.0/18"
  availability_zone = var.pub2_az

  # Required for EKS. Instances launched into the subnet should be assigned a public IP address.
  map_public_ip_on_launch = true

  tags = {
    Name                        = "public-us-east-2b"
    "kubernetes.io/cluster/eks" = "shared"
    "kubernetes.io/role/elb"    = 1
  }
}

resource "aws_subnet" "private_1" {
  vpc_id = aws_vpc.secret_vpc.id
  cidr_block = "192.168.128.0/18"
  
  availability_zone = var.pv1_az

  # A map of tags to assign to the resource.
  tags = {
    Name                              = "private-us-east-2a"
    "kubernetes.io/cluster/eks"       = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_subnet" "private_2" {
  # The VPC ID
  vpc_id = aws_vpc.secret_vpc.id

  # The CIDR block for the subnet.
  cidr_block = "192.168.192.0/18"

  # The AZ for the subnet.
  availability_zone = var.pv2_az

  # A map of tags to assign to the resource.
  tags = {
    Name                              = "private-us-east-2b"
    "kubernetes.io/cluster/eks"       = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}