# Terraform Demo

![image](https://user-images.githubusercontent.com/7464927/124938809-76cea800-dfbd-11eb-8f5f-8c9843cbf487.png)

## Introduction & Goals

The goal of this project is the use Infrastructure-as-Code to do the following:

- Create an EC2 Instance
- Deploy a custom VPC on a custom subnet
- Use a public IP address to SSH into the server
- Setup a web server to handle web traffic

## Application

- I'll be using Terraform to define and provision the infrastructure. Terraform is an open-source infrastructure as code software tool created by HashiCorp.
- I'll be using Terraform on my mac. To install Terraform, you need to do the following:

```
brew install terraform
```

- Once Terraform is installed, you can create a .tf file that will have your HCL configuration. Then initialize it with this command:

```
terraform init
```

For this project, I created a main.tf file.

## Script - main.tf

- Connect to AWS, add the AWS provider on your script. For more AWS provider documentation and usage, go to https://registry.terraform.io/providers/hashicorp/aws/latest/docs

```HCL
provider "aws" {
  region = "us-west-1"
  access_key = "<Insert AWS access key here>"
  secret_key = "<Insert AWS secret key here>"
}
```

- Create VPC with a 10.0.0.0/16 cidr block, assign a name to that VPC.

```HCL
# 1. Create VPC
resource "aws_vpc" "demoVPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Demo VPC"
  }
}
```

- Setup an internet gateway

```HCL
# 2. Create Internet Gateway
resource "aws_internet_gateway" "demoIGW" {
  vpc_id = aws_vpc.demoVPC.id

  tags = {
    Name = "Demo IGW"
  }
}
```

- Create a custom route table and subnet then associate them together.

```HCL
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
```

- Create SG to allow Port 22, 80, 443 and call it allow_web_traffic. The egress part means it just allows outbound for ANY protocol to any IP

```HCL
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
```

- Create a NIC with a private IP and associate it to a subnet and SG

```HCL
# 7. Create a network interface with an IP in the subnet that was created in STEP 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.demoSubnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_traffic.id]
}
```

- Create an EIP, the depends_on means that there should be an IGW for this to work

```HCL
# 8. Assign an elastic IP to the network interface created in STEP 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"

  depends_on = [aws_internet_gateway.demoIGW]
}
```

- Lastly, spin up an ubuntu server with userdata as the webserver.

```HCL
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
```

## Running the Script

- To execute the script, you do a terraform apply
![Screen Shot 2021-07-17 at 3 09 05 PM](https://user-images.githubusercontent.com/7464927/126050319-9382c507-8677-470d-9ef4-a9760c41f94a.png)

- Login to your AWS Console to confirm the resources has been created.
![image](https://user-images.githubusercontent.com/7464927/126050336-3748a14e-5496-4a61-90e5-494e55fbc9d0.png)
