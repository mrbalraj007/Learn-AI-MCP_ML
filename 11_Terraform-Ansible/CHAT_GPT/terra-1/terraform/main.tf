resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.generated.private_key_pem
  filename        = "${path.module}/devtools-key.pem"
  file_permission = "0400"
}

resource "local_file" "public_key" {
  content  = tls_private_key.generated.public_key_openssh
  filename = "${path.module}/devtools-key.pub"
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = tls_private_key.generated.public_key_openssh
}

module "ec2_instance" {
  source = "./modules/ec2"

  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name
  environment   = var.environment
}
