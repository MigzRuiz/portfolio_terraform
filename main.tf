provider "aws" {
  region = "us-west-1"
  access_key = ""
  secret_key = ""
}

# 1. Create VPC
resource "aws_vpc" "demoVPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Demo VPC"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "demoIGW" {
  vpc_id = aws_vpc.demoVPC.id

  tags = {
    Name = "Demo IGW"
  }
}

# 3. Create Custom Route Table
resource "aws_route_table" "demoRouteTable" {
  vpc_id = aws_vpc.demoVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demoIGW.id
  }

  tags = {
    Name = "Demo Route Table"
  }
}

# 4. Create a Subnet
resource "aws_subnet" "demoSubnet-1" {
  vpc_id     = aws_vpc.demoVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1a"

  tags = {
    Name = "Demo Subnet-1"
  }
}

# 5. Associate subnet with Route Table
resource "aws_route_table_association" "A" {
  subnet_id = aws_subnet.demoSubnet-1.id
  route_table_id = aws_route_table.demoRouteTable.id
}

# 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.demoVPC.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web_traffic"
  }
}

# 7. Create a network interface with an IP in the subnet that was created in STEP 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.demoSubnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_traffic.id]
}

# 8. Assign an elastic IP to the network interface created in STEP 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"

  depends_on = [aws_internet_gateway.demoIGW]
}

# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "demoInstance" {
  ami = "ami-0d382e80be7ffdae5"
  instance_type = "t2.micro"
  availability_zone = "us-west-1a"
  key_name = "terraform-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c "echo HELLO WORLD > /var/www/html/index.html"
              EOF

  tags = {
    Name = "demoServer"
  }
}