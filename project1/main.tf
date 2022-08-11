provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}
# create a vpc
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_vpc"
  }
}

# create internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
}

# create custom route table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id

  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }
  tags = {
    "Name" = "prod-route"
  }
}

# Create a subnet
resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_prefix[0].cidr_block
  availability_zone = var.availability_zone
  tags = {
    Name = var.subnet_prefix[0].name
  }

}

# Associate subnet with route table

resource "aws_route_table_association" "ass" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# create security group to allow port 22, 80, 443

resource "aws_security_group" "allow_web" {
  name        = "Allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "https traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh traffic"
    from_port   = 2
    to_port     = 2
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
    "Name" = "allow-traffice"
  }

}

# create a network interface with an ip in the subnet that was create in step 4

resource "aws_network_interface" "ni" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web]
}

# Assign an elastic IP to the network interface in step 7

resource "aws_eip" "eip" {
  vpc                       = true
  network_interface         = aws_network_interface.ni.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]

}


# reate ubuntu server and install/enable apache2

resource "aws_instance" "web_server" {
  ami               = "ami-085925f297f89fce1"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = var.key_name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.ni.id
  }

  user_data = <<-EOF
           #!/bin/bash
           sudo apt update -y
           sudo apt install apache2 -y
           sudo systemctl start apache2
           sudo bash -c "echo your very first web server > /var/www/html/index.html"
           EOF
  tags = {
    "Name" = "web_server"
  }
}