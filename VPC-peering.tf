## Sunday June 07 2020 17:30 IST 
## Purpose ## Terraform template to configure VPC Peering (In same region)  ##
## Created by Nikhil Kulkarni ###

#########################################################################################################################

# create the VPC. You can change the VPC name and CIDR block as per your requirement.
resource "aws_vpc" "VPC_1" {
  cidr_block           = "10.10.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "VPC 1"
  }
} # end resource


############### Create and Attach an Internet Gateway to VPC ##################

# Create the Internet Gateway
resource "aws_internet_gateway" "Gateway_1" {
  vpc_id = aws_vpc.VPC_1.id
  tags = {
    Name = "Terraform Internet Gateway"
  }
} # end resource


############### Public Subnet for EC2 Instance  ##################

resource "aws_subnet" "Public_Subnet" {
  vpc_id                  = aws_vpc.VPC_1.id
  cidr_block              = "10.10.10.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1a"
  tags = {
    Name = "Public Subnet"
  }
} # end resource


# Create the Route Table
resource "aws_route_table" "VPC1_route_table" {
  vpc_id = aws_vpc.VPC_1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Gateway_1.id
  }
  route {
    cidr_block                = "10.20.20.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary.id
  }
  tags = {
    Name = "VPC_1 Route Table"
  }
} # end resource


# Associate the Route Table with the Subnet1
resource "aws_route_table_association" "VPC1_RTA" {
  subnet_id      = aws_subnet.Public_Subnet.id
  route_table_id = aws_route_table.VPC1_route_table.id
} # end resource


######################### Instance Security Group ###########################

resource "aws_security_group" "VPC1_SG" {
  vpc_id      = aws_vpc.VPC_1.id
  name        = "VPC_1 Security Group"
  description = "VPC1 Security Group"

  # allow ingress of port 22
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
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
    Name        = "VPC1 Security Group"
    Description = "VPC1 Security Group"
  }
} # end resource


################ EC2 Instance ##############################

resource "aws_instance" "Instance1" {
  ami             = "ami-005956c5f0f757d37"
  instance_type   = "t2.micro"
  key_name        = "mumbai"  # Replace with your key
  subnet_id       = aws_subnet.Public_Subnet.id
  security_groups = ["${aws_security_group.VPC1_SG.id}"]
  tags = {
    Name = "Instance_1"
  }
}


########################## VPC 2 ###############################

resource "aws_vpc" "VPC_2" {
  cidr_block           = "10.20.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "VPC 2"
  }
} # end resource


############### Create and Attach an Internet Gateway to VPC ##################

resource "aws_internet_gateway" "Gateway_2" {
  vpc_id = aws_vpc.VPC_2.id
  tags = {
    Name = "Terraform Internet Gateway"
  }
} # end resource


############### Private Subnet for EC2 Instance in VPC 2  ##################

resource "aws_subnet" "Private_Subnet" {
  vpc_id                  = aws_vpc.VPC_2.id
  cidr_block              = "10.20.20.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "ap-south-1b"
  tags = {
    Name = "Private Subnet"
  }
} # end resource


######################### Create Private Route Table #########################

resource "aws_route_table" "VPC2_route_table" {
  vpc_id = aws_vpc.VPC_2.id
  route {
    cidr_block                = "10.10.10.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary.id
  }

  tags = {
    Name = "VPC_2 Route Table"
  }
} # end resource

# Associate the Route Table with the Subnet1
resource "aws_route_table_association" "VPC2_RTA" {
  subnet_id      = aws_subnet.Private_Subnet.id
  route_table_id = aws_route_table.VPC2_route_table.id
} # end resource


######################### Instance Security Group VPC 2 ###########################

resource "aws_security_group" "VPC2_SG" {
  vpc_id      = aws_vpc.VPC_2.id
  name        = "VPC_2 Security Group"
  description = "VPC2 Security Group"

  # allow ingress of port 22
  ingress {
    cidr_blocks = ["10.10.10.0/24"]  # Incoming is only allowed form Purblic subnet.(VPC1)
    from_port   = 22
    to_port     = 22
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
    Name        = "VPC1 Security Group"
    Description = "VPC2 Security Group"
  }
} # end resource


################ EC2 Instance ##############################

# Launch EC2 instance in subnet 1.
resource "aws_instance" "Instance2" {
  ami             = "ami-005956c5f0f757d37"
  instance_type   = "t2.micro"
  key_name        = "mumbai"
  subnet_id       = aws_subnet.Private_Subnet.id
  security_groups = ["${aws_security_group.VPC2_SG.id}"]
  tags = {
    Name = "Instance_2"
  }
}


######################### VPC Peering Connection ###########################

resource "aws_vpc_peering_connection" "primary2secondary" {
  vpc_id      = aws_vpc.VPC_1.id
  peer_vpc_id = aws_vpc.VPC_2.id
  auto_accept = true # This only works if both VPCs are owned by the same account.
}

###################### THE END ###########################################
