variable "public_key_path" {
  default = "./mykey.pub"
}

variable "private_key_path" {
  default = "./mykey"
}

variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default     = "10.1.0.0/16"
}

variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default     = "10.1.0.0/24"
}

variable "instance_ami" {
  description = "AWS EC2 instance AMI"
  default     = "ami-04bb0cc469b2b81cc"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}