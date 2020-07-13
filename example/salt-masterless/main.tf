provider "aws" {
  region = "us-west-2"
}

module "network_access" {
  source = "./network-access"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "deploy-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "web" {
  ami                         = var.instance_ami
  instance_type               = var.instance_type
  subnet_id                   = module.network_access.subnet_id
  vpc_security_group_ids      = [module.network_access.sg_id]
  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    port        = 22
    private_key = file(var.private_key_path)
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

output "instance_ip" {
  value = aws_instance.web.public_ip
}