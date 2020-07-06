provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "deploy" {
  key_name   = "deploy-key"
  public_key = file("./mykey.pub")
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Environment = var.environment_tag
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Environment = var.environment_tag
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_subnet
  map_public_ip_on_launch = "true"
  availability_zone       = var.availability_zone
  tags = {
    Environment = var.environment_tag
  }
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Environment = var.environment_tag
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_security_group" "sg_22_80" {
  name   = "sg_22"
  vpc_id = aws_vpc.vpc.id

  # SSH access from the VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

  tags = {
    Environment = var.environment_tag
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.sg_22_80.id]
  key_name                    = aws_key_pair.deploy.key_name
  associate_public_ip_address = true

  tags = {
    Name = "HelloWorld"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    port        = 22
    private_key = file("./mykey")
    timeout     = "1m"
  }

  provisioner "file" {
    source      = "${path.root}/salt"
    destination = "/tmp/salt"
  }

  provisioner "remote-exec" {
    inline = [
      # Install and bootstrap salt
      "curl -L https://bootstrap.saltstack.com | sudo sh",
      # Remove directory /srv/salt to ensure it is clear
      "sudo rm -rf /srv/salt",
      # Move state tree from temporary directory to /srv/salt
      "sudo mv /tmp/salt /srv/salt",
      # Run salt-call
      "sudo salt-call --local  state.highstate --file-root=/srv/salt --pillar-root=/srv/pillar --retcode-passthrough -l info"
    ]
  }

  # This is the equivalent salt-masterless block of the above file/remote-exec combination:
  # provisioner "salt-masterless" {
  #   local_state_tree  = "${path.root}/salt"
  #   remote_state_tree = "/srv/salt"
  # }
}

output "id" {
  value = aws_instance.web.public_ip
}
