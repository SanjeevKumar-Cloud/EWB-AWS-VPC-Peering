terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project = "EWB-VPC-Peering"
      Student = var.student_name
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ------------------------------------------------------------------------------
# VPC A (10.10.0.0/16)
# ------------------------------------------------------------------------------
resource "aws_vpc" "vpc_a" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "ewb-vpc-a"
  }
}

resource "aws_subnet" "subnet_a_public" {
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "ewb-a-public"
  }
}

resource "aws_subnet" "subnet_a_private" {
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = {
    Name = "ewb-a-private"
  }
}

resource "aws_internet_gateway" "igw_a" {
  vpc_id = aws_vpc.vpc_a.id
  tags = {
    Name = "ewb-igw-a"
  }
}

resource "aws_route_table" "rt_a_public" {
  vpc_id = aws_vpc.vpc_a.id
  tags = {
    Name = "ewb-rt-a-public"
  }
}

resource "aws_route_table_association" "rta_public" {
  subnet_id      = aws_subnet.subnet_a_public.id
  route_table_id = aws_route_table.rt_a_public.id
}

resource "aws_route" "r_a_public_internet" {
  route_table_id         = aws_route_table.rt_a_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_a.id
}

resource "aws_route" "r_a_public_peering" {
  route_table_id            = aws_route_table.rt_a_public.id
  destination_cidr_block    = "10.20.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

resource "aws_route_table" "rt_a_private" {
  vpc_id = aws_vpc.vpc_a.id
  tags = {
    Name = "ewb-rt-a-private"
  }
}

resource "aws_route_table_association" "rta_private_a" {
  subnet_id      = aws_subnet.subnet_a_private.id
  route_table_id = aws_route_table.rt_a_private.id
}

resource "aws_route" "r_a_private_peering" {
  route_table_id            = aws_route_table.rt_a_private.id
  destination_cidr_block    = "10.20.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

# ------------------------------------------------------------------------------
# VPC B (10.20.0.0/16)
# ------------------------------------------------------------------------------
resource "aws_vpc" "vpc_b" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "ewb-vpc-b"
  }
}

resource "aws_subnet" "subnet_b_private" {
  vpc_id                  = aws_vpc.vpc_b.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = {
    Name = "ewb-b-private"
  }
}

resource "aws_route_table" "rt_b_private" {
  vpc_id = aws_vpc.vpc_b.id
  tags = {
    Name = "ewb-rt-b-private"
  }
}

resource "aws_route_table_association" "rta_private_b" {
  subnet_id      = aws_subnet.subnet_b_private.id
  route_table_id = aws_route_table.rt_b_private.id
}

resource "aws_route" "r_b_private_peering" {
  route_table_id            = aws_route_table.rt_b_private.id
  destination_cidr_block    = "10.10.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

# ------------------------------------------------------------------------------
# VPC Peering Connection (VPC A <-> VPC B)
# ------------------------------------------------------------------------------
resource "aws_vpc_peering_connection" "peering" {
  peer_vpc_id = aws_vpc.vpc_b.id
  vpc_id      = aws_vpc.vpc_a.id
  auto_accept = true
  tags = {
    Name = "ewb-a-b-peer"
  }
}

# ------------------------------------------------------------------------------
# Security Groups
# ------------------------------------------------------------------------------
resource "aws_security_group" "sg_bastion" {
  name        = "ewb-sg-bastion"
  description = "Bastion security group for administrative SSH"
  vpc_id      = aws_vpc.vpc_a.id

  ingress {
    description = "SSH from authorized workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ewb-sg-bastion"
  }
}

resource "aws_security_group" "sg_app_a" {
  name        = "ewb-sg-app-a"
  description = "Security group for App-A private host"
  vpc_id      = aws_vpc.vpc_a.id

  ingress {
    description = "SSH from Bastion private IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.1.10/32"]
  }

  ingress {
    description = "ICMP Echo Request from App-B"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["10.20.1.10/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ewb-sg-app-a"
  }
}

resource "aws_security_group" "sg_app_b" {
  name        = "ewb-sg-app-b"
  description = "Security group for App-B private host"
  vpc_id      = aws_vpc.vpc_b.id

  ingress {
    description = "SSH from Bastion private IP via peering"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.1.10/32"]
  }

  ingress {
    description = "ICMP Echo Request from App-A"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["10.10.2.10/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ewb-sg-app-b"
  }
}

# ------------------------------------------------------------------------------
# EC2 Instances
# ------------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.subnet_a_public.id
  private_ip                  = "10.10.1.10"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg_bastion.id]

  root_block_device {
    volume_size           = 8
    delete_on_termination = true
  }

  tags = {
    Name = "ewb-bastion"
  }
}

resource "aws_instance" "app_a" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.subnet_a_private.id
  private_ip                  = "10.10.2.10"
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.sg_app_a.id]

  root_block_device {
    volume_size           = 8
    delete_on_termination = true
  }

  tags = {
    Name = "ewb-app-a"
  }
}

resource "aws_instance" "app_b" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.subnet_b_private.id
  private_ip                  = "10.20.1.10"
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.sg_app_b.id]

  root_block_device {
    volume_size           = 8
    delete_on_termination = true
  }

  tags = {
    Name = "ewb-app-b"
  }
}
