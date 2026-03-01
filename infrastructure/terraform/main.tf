terraform {
  backend "s3" {
    bucket         = "fullstack-template-terraform-state"
    key            = "fullstack-template/staging/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_vpc" "default" {
  default = true
}

# Get IGWs attached to default VPC
data "aws_internet_gateway" "existing" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Check if attached
locals {
  igw_attached = length(data.aws_internet_gateway.existing.id) > 0
}

# Create only if missing
resource "aws_internet_gateway" "attached_to_default" {
  count  = local.igw_attached ? 0 : 1
  vpc_id = data.aws_vpc.default.id

  tags = {
    Name = "default-vpc-igw"
  }
}

# Pick correct IGW ID
locals {
  igw_id = local.igw_attached ? data.aws_internet_gateway.existing.id : aws_internet_gateway.attached_to_default[0].id
}

# Getting main route table
data "aws_route_table" "main" {
  vpc_id = data.aws_vpc.default.id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# Is route table has a entry pointing to IGW
locals {
  default_route_exists = length([
    for r in data.aws_route_table.main.routes :
    r
    if r.cidr_block == "0.0.0.0/0"
    && try(r.gateway_id, "") == local.igw_id
  ]) > 0
}

# If not add the IGW entry in route table
resource "aws_route" "internet_access" {
  count = local.default_route_exists ? 0 : 1

  route_table_id         = data.aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = local.igw_id
}

resource "aws_security_group" "sg_01" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name   = "${var.project_name}-db-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "Allow Postgres from VPC only"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_instance" "server_01" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnets.default.ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.sg_01.id]

  associate_public_ip_address = true

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "${var.project_name}-${var.env}-server"
  }
}

resource "aws_instance" "db_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro" 
  subnet_id     = data.aws_subnets.default.ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.db_sg.id]

  associate_public_ip_address = false
  disable_api_termination     = true

  user_data = file("${path.module}/user_data.sh")

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-shared-db"
    Role = "database"
  }
}