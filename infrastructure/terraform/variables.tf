variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "env" {
  type = string
} # staging | prod

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
  default = "t3.micro"
}

variable "key_name" {
  type = string
} # existing EC2 keypair name

variable "domain_name" {
  type    = string
  default = ""
}