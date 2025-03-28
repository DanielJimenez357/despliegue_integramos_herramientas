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
  key_name                    = "clave"
  user_data = <<-EOF
            #!/bin/bash
            apt-get update
            apt-get install -y ca-certificates curl gnupg
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            systemctl start docker
            systemctl enable docker
            docker run -d -p 80:8080 -p 50000:50000 --restart=on-failure jenkins/jenkins:lts-jdk17

            sleep 30

            docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword >> /var/log/cloud-init-output.log
            EOF
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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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


