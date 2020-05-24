### Sunday May 24 2020 23:50 IST 
## Purpose ## Terraform template to launch Application Load Balancer with two EC2 instances. ##
## Created by Nikhil Kulkarni ###

#########################################################################################################################



provider "aws" {
  version = "~> 2.0"
  access_key = access_key  # If you have already configured AWS-CLI then this is not required.
  secret_key = secret_key  # If you have already configured AWS-CLI then this is not required.
  region     = "ap-south-1"
}

# create the VPC. You can change the VPC name and CIDR block as per your requirement.
resource "aws_vpc" "Terraform_VPC" {
  cidr_block           = "10.10.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
tags = {
    Name = "Terraform VPC"
    }
} # end resource

# create the Subnet 1. You can change the subnet name, CIDR block as per your requirement.
resource "aws_subnet" "Terraform_Subnet1" {
  vpc_id                  = aws_vpc.Terraform_VPC.id
  cidr_block              = "10.10.10.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1a"
tags = {
   Name = "Terraform Subnet1"
}
} # end resource

# create the Subnet 2. You can change the subnet name, CIDR block as per your requirement.
resource "aws_subnet" "Terraform_Subnet2" {
  vpc_id                  = aws_vpc.Terraform_VPC.id
  cidr_block              = "10.10.20.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1b"
tags = {
   Name = "Terraform Subnet2"
}
} # end resource


# Create the Internet Gateway
resource "aws_internet_gateway" "Terraform_IG" {
 vpc_id = aws_vpc.Terraform_VPC.id
 tags = {
        Name = "Terraform Internet Gateway"
}
} # end resource

# Create the Route Table
resource "aws_route_table" "Terraform_route_table" {
 vpc_id = aws_vpc.Terraform_VPC.id
 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Terraform_IG.id
  }

 tags = {
        Name = "Terraform Route Table"
}
} # end resource


# Associate the Route Table with the Subnet1
resource "aws_route_table_association" "Terraform_association_Sub1" {
  subnet_id      = aws_subnet.Terraform_Subnet1.id
  route_table_id = aws_route_table.Terraform_route_table.id
} # end resource

# Associate the Route Table with the Subnet2
resource "aws_route_table_association" "Terraform_association_Sub2" {
  subnet_id      = aws_subnet.Terraform_Subnet2.id
  route_table_id = aws_route_table.Terraform_route_table.id
} # end resource


# Create the Security Group for instance
resource "aws_security_group" "Terraform_SG" {
  vpc_id       = aws_vpc.Terraform_VPC.id
  name         = "Terraform Security Group"
  description  = "Terraform Security Group"
  
  # allow ingress of port 22
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  } 
   ingress {
    cidr_blocks = ["10.10.0.0/16"]  ## http request from ALB will only be allowed. 
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  } 
    # allow egress of all ports
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
   Name = "Terraform Security Group"
   Description = "Terraform Security Group"
}
} # end resource


# Create the Security Group for Classic Load Balancer
resource "aws_security_group" "Terraform_CLB_SG" {
  vpc_id       = aws_vpc.Terraform_VPC.id
  name         = "Terraform CLB SG"
  description  = "Terraform CLB SG"
  
  # allow ingress of port 80
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  } 
 # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
   Name = "Terraform CLB SG"
   Description = "Terraform CLB SG"
}
} # end resource


# Launch an EC2 instance in subnet 1.
resource "aws_instance" "Terraform_instance1" {
  ami = "ami-0470e33cd681b2476"
  instance_type = "t2.micro"
  key_name = "mumbai"
  subnet_id = aws_subnet.Terraform_Subnet1.id
  security_groups = ["${aws_security_group.Terraform_SG.id}"]
tags = {
    Name = "Terraform_Instance"
  }
}


# Launch an EC2 instance in subnet 2
resource "aws_instance" "Terraform_instance2" {
  ami = "ami-0470e33cd681b2476"
  instance_type = "t2.micro"
  key_name = "mumbai"
  subnet_id = aws_subnet.Terraform_Subnet2.id
  security_groups = ["${aws_security_group.Terraform_SG.id}"]
tags = {
    Name = "Terraform_Instance"
  }
}

# Luanch ALB
resource "aws_alb" "Terraform_ALB" {
	name		=	"Terraform-ALB"
	internal	=	false
	security_groups	=	[aws_security_group.Terraform_CLB_SG.id]
	subnets		=	[aws_subnet.Terraform_Subnet1.id , aws_subnet.Terraform_Subnet2.id]
	enable_deletion_protection	=	true
}

#Creation of the load balancer target group.
resource "aws_alb_target_group" "Terraform_TG" {
	name	= "albfronthttps"
	vpc_id	= aws_vpc.Terraform_VPC.id
	port	= "80"
	protocol	= "HTTP"
	health_check {
                path = "/index.html"
                port = "80"
                protocol = "HTTP"
                healthy_threshold = 2
                unhealthy_threshold = 2
                interval = 5
                timeout = 2
                matcher = "200-308"
        }
}


#Assignment of the EC2 instances to the target group. Terraform_instance1.
resource "aws_alb_target_group_attachment" "backend_instance1" {
  target_group_arn = aws_alb_target_group.Terraform_TG.arn
  target_id        = aws_instance.Terraform_instance1.id
  port             = 80
}

#Assignment of the EC2 instances to the target group. Terraform_instance2.
resource "aws_alb_target_group_attachment" "backend_instance2" {
  target_group_arn = aws_alb_target_group.Terraform_TG.arn
  target_id        = aws_instance.Terraform_instance2.id
  port             = 80
}


# Creat load balancer listner. You can change the Port and Protocol as per your requirement.
resource "aws_alb_listener" "alb_listener" {  
  load_balancer_arn = aws_alb.Terraform_ALB.arn
  port              = 80  
  protocol          = "HTTP"
  
  default_action {    
    target_group_arn = aws_alb_target_group.Terraform_TG.arn
    type             = "forward"  
  }
}
