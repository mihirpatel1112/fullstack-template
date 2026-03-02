variable "aws_region" {
  type = string
  default = "ap-southeast-2"
}

variable "project_name" {
  type = string
}

variable "env" {
  type = string
} # staging | prod

variable "unbuntu_ami_id" {
  type = string
  default = "099720109477"
}

variable "ubuntu_image" {
  type = string
  default = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type = string
} # existing EC2 keypair name

variable "domain_name" {
  type    = string
  default = ""
}