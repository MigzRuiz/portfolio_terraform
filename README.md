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

## Script

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
