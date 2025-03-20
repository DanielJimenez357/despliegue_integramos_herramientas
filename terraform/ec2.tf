terraform {
    required_providers {
    aws = {
        source  = "hashicorp/aws"
    }
    }
    required_version = ">= 1.2.0"
}

provider "aws" {
    shared_config_files      = ["/Users/Usuario/.aws/config"]
    shared_credentials_files = ["/Users/Usuario/.aws/credentials"]
}

resource "aws_instance" "web" {
  ami                         = var.ami
  instance_type               = var.instancia
  subnet_id                   = aws_subnet.subnetPublica.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.grupo_seguridad.id]
  key_name                    = aws_key_pair.claves.key_name
  user_data = <<-EOF
            #!/bin/bash
            yum update -y
            yum install -y httpd
            systemctl start httpd
            systemctl enable httpd
            echo "<html><body><h1>¡Bienvenido a mi servidor web con Terraform!</h1></body></html>" > /var/www/html/index.html
            EOF
}

resource "tls_private_key" "mi_clave" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "claves" {
  key_name   = "clave"
  public_key = tls_private_key.mi_clave.public_key_openssh
}

resource "local_file" "clave_privada" {
  content  = tls_private_key.mi_clave.private_key_pem
  filename = "clave"
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

resource "aws_security_group" "grupo_seguridad" {
  name        = "grupo_seguridad"
  description = "grupo_seguridad"
  vpc_id      = aws_vpc.vpc1.id

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
    Name = "grupo_seguridad"
  }
}


