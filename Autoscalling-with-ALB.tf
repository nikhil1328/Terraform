## Wednesday May 27 2020 21:40 IST 
## Purpose ## Terraform template to create Autoscalling with ALB.  ##
## Created by Nikhil Kulkarni ###

#########################################################################################################################

provider "aws" {
  version = "~> 2.0"
  access_key = access_key  # If you have already configured AWS-CLI then this is not required.
  secret_key = secret_key  # If you have already configured AWS-CLI then this is not required.
  region = "ap-south-1"
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
  vpc_id      = aws_vpc.Terraform_VPC.id
  name        = "Terraform Security Group"
  description = "Terraform Security Group"

  # allow ingress of port 22
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["10.10.0.0/16"]
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
    Name        = "Terraform Security Group"
    Description = "Terraform Security Group"
  }
} # end resource



# Create the Security Group for instance
resource "aws_security_group" "Terraform_ALB_SG" {
  vpc_id      = aws_vpc.Terraform_VPC.id
  name        = "Terraform ALB Security Group"
  description = "Terraform ALB Security Group"

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
    Name        = "Terraform ALB Security Group"
    Description = "Terraform ALB Security Group"
  }
} # end resource


################ Application Load Balancer ################

resource "aws_lb" "Terraform_ALB" {
  name            = "application-load-balancer"
  subnets         = [aws_subnet.Terraform_Subnet1.id, aws_subnet.Terraform_Subnet2.id]
  security_groups = [aws_security_group.Terraform_ALB_SG.id]
  internal        = false
  idle_timeout    = 60
  tags = {
    Name = "Terraform ALB"
  }
}

resource "aws_lb_target_group" "Terraform_ALB_TG" {
  name     = "alb-target-group"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = aws_vpc.Terraform_VPC.id
  tags = {
    name = "alb_target_group"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 10
    path                = "/"
    port                = 80
  }
}

resource "aws_lb_listener" "Terraform_ALB_Listener" {
  load_balancer_arn = aws_lb.Terraform_ALB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.Terraform_ALB_TG.arn
    type             = "forward"
  }
}


####### AutoScalling ##########

resource "aws_launch_configuration" "Terraform_LC" {
  image_id        = "ami-0470e33cd681b2476"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.Terraform_SG.id]
  key_name        = "mumbai"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "Terraform_ASG" {
  launch_configuration = aws_launch_configuration.Terraform_LC.id
  vpc_zone_identifier  = [aws_subnet.Terraform_Subnet1.id, aws_subnet.Terraform_Subnet2.id]
  target_group_arns    = [aws_lb_target_group.Terraform_ALB_TG.id]
  min_size             = 2
  max_size             = 4
}


resource "aws_autoscaling_attachment" "alb_autoscale" {
  alb_target_group_arn   = aws_lb_target_group.Terraform_ALB_TG.arn
  autoscaling_group_name = aws_autoscaling_group.Terraform_ASG.id
}
