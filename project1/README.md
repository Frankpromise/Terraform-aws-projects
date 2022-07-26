# Deploying a web server on AWS using Terraform

## INTRODUCTION

In this mini project, i will set up a VPC with a single subnet. Then a route table with an internet gateway to allow traffic in and out of the VPC.
A security group will be created to allow inbound traffic over port 80, 443 and 22. A network interface will be added to serve as a security layer
in the instance level to direct traffic to the subnet created. A further step will be taken to create an elastic ip that will create a public ip address which will be added to our already created network interface. Finally we will create an ec2 instance which will be used to host an apache2 webserver.

## FOLDER CONTENT
1. `main.tf` containing configurations
2. `variables.tf` containing variables referenced in the `main.tf` file
3. `outputs.tf` file


__STEPS:__

1. set up a provider
2. create a vpc
3. create internet gateway
4. create custom route table
5. create a subnet
6. associate subnet with route table
7. create security group to allow port 22, 80, 443
8. create a network interface with an ip in the subnet that was create in step 4
9. Assign an elastic IP to the network interface in step 7
10. create ubuntu server and install/enable apache2

__PREREQUISITES:__
1. AWS account
2. Good knowledge of AWS managament console
3. Knowledge of VPC and subnets


## CONCEPTS DEFINITION
1 `providers`: Terraform providers are plugins that implement resource types. Providers contain all 
the code needed to authenticate and connect to a service—typically from a public cloud provider—on behalf of the user.

2. `VPC`: A virtual network dedicated to your aws account.

3. `CIDR_BLOCK`: Classless Inter-Domain Routing (CIDR) block basically is a method for allocating IP addresses 
and IP routing. When you create a network or route table, you need to specify what range are you working in. 
"0.0.0.0" means that it will match to any IP address. 

4. `Internet gateway`: Allows communication between instances in your VPC and the internet using VPC route tables 
for internet-routable traffic. An Internet Gateway supports IPv4 and IPv6 traffic.

5. `subnet`:  subnetting is the process breaking down an IP address into smaller units that can be assigned to 
individual network units within the original network.Subnet is a network inside a network.

6. `Availability zone`:  Availability zones (AZs) are isolated locations within data center regions from which public cloud services originate and operate.

7. `Route tables` : A routing table contains the information necessary to forward a packet along the best path toward its destination.

8. `security groups`: A security group is an AWS firewall solution that performs one primary function: to filter incoming and outgoing traffic from an EC2 instance. It accomplishes this filtering function at the TCP and IP layers, via their respective ports, and source/destination IP addresses. 

9. `network interface`: A network interface is the point of interconnection between a computer and a private or public network.

10. `elastic ip`:An Elastic IP address is a public IPv4 address, which is reachable from the Internet. If your instance does not have a public IPv4 address, you can associate an Elastic IP address with your instance to enable the communication with the Internet. For example, to connect to your instance from your local computer.


__1. set up a provider__

```
provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}
```

Since we will be deploying infrastructure to aws, i used aws cloud provider pluggins. The variables for the region, access_key 
and secret access_key can be found in the `variables.tf` file. Make sure you create a `terraform.fvars` file to store your access_key and secret access_key.

__2. create a vpc__
```
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_vpc"
  }
}
```
Here, we create a vpc called `my_vpc` with a cidr_block of `10.0.0.0/16`

__3. create internet gateway__

```
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
}
```
Here, we create an internet gateway named `gw` and reference the vpc id created in step 2

__4. create custom route table__

```
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
```

Here, we create a route table and attach the internet gateway previously created to allow our vpc communicate with the outside world.

__5. create a subnet__

```
resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_prefix[0].cidr_block
  availability_zone = var.availability_zone
  tags = {
    Name = var.subnet_prefix[0].name
  }

}
```
Here, we create a subnet with a vpc id referenced from step 2. Then define a cidr block which has its content specified as a list of object in the
`terraform.fvars` file. Then an availability zone referenced from the `varaibles.tf` file. Also the tags is referenced as an object from `terraform.tfvars` file.

__6. associate subnet with route table__

```
resource "aws_route_table_association" "ass" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.prod-route-table.id
}
```

Here, we associate our route table to our subnet to allow traffic from outside of the vpc

__7. create security group to allow port 22, 80, 443__

```
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
```

Here, we create a resource block that will allow http access on port 80, https access on port 443 and ssh access on port 22

__8. create a network interface with an ip in the subnet that was create in step 4__

```
resource "aws_network_interface" "ni" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web]
}
```

Here we create a network interface resource block that if assigned to an ec2 instance will allow connection to a private network within the vpc.

__9. Assign an elastic IP to the network interface in step 7__

```
resource "aws_eip" "eip" {
  vpc                       = true
  network_interface         = aws_network_interface.ni.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]

}

```
Here we associate an elastic ip address to the network interface to allow communication to and from the vpc.


__10. create ubuntu server and install/enable apache2__

```
resource "aws_instance" "web_server" {
  ami               = "ami-085925f297f89fce1"
  instance_type     = "t2.micro"
  availability_zone = var.availability_zone
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
```

finally we deploy our webserver to install http and deploy a simple webserver

__NOTE__
All snippets of code above is contained in the `main.tf` file in the folder. Make sure to also create a `variables.tf` file, `outputs.tf` file and 
`terraform.tfvars` file.

__CONTENT OF `variables.tf` file__

```
variable "access_key" {}
variable "secret_key" {}
variable "key_name" {}
variable "region" {

  default = "us-east-1"
}

variable "availability_zone" {
  default = "us-east-1a"

}

variable "subnet_prefix" {}
```

__CONTENT of `outputs.tf` file __

```
output "server_public" {
  value = aws_eip.eip.associate_with_private_ip

}

output "server_private_ip" {
  value = aws_instance.web_server.private_ip

}

output "server_id" {
  value = aws_instance.web_server.id

}
```

__CONTENT of `terraform.tfvars` file__

```
access_key = ${aws_access_key}
secret_key = ${aws_secret_key}
key_name = ${name of your key pair}
subnet_prefix = [{ cidr_block = "10.0.1.0/24", name = "prod_subnet" }]
```

## HOW TO RUN THE CODE

1. `terraform fmt` to format the code
2. `terraform validate` to check for syntax or any form of errors
3. `terraform plan` to check the resources that will be deployed
4. ` terraform apply` to deploy the resources to aws cloud
5. `terraform destroy` to destroy the resources if no longer needed
