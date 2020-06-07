## Sunday June 07 2020 17:30 IST 
## Purpose ## Terraform template to Launch an RDS Instance. (Data Base Instance)  ##
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

############### Create and Attach an Internet Gateway to VPC ##################

# Create the Internet Gateway
resource "aws_internet_gateway" "Terraform_IG" {
  vpc_id = aws_vpc.Terraform_VPC.id
  tags = {
    Name = "Terraform Internet Gateway"
  }
} # end resource


############### Public Subnet for EC2 Instance ##################

# create the Subnet . You can change the subnet name, CIDR block as per your requirement.
resource "aws_subnet" "Public_Subnet" {
  vpc_id                  = aws_vpc.Terraform_VPC.id
  cidr_block              = "10.10.10.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1a"
  tags = {
    Name = "Public Subnet"
  }
} # end resource


############### Private Subnets for RDS Instance ##################

# create the Private Subnet 1. You can change the subnet name, CIDR block as per your requirement.
resource "aws_subnet" "Private_Subnet1" {
  vpc_id                  = aws_vpc.Terraform_VPC.id
  cidr_block              = "10.10.40.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "ap-south-1a"
  tags = {
    Name = "Private Subnet1"
  }
} # end resource


# create the Private Subnet 2. You can change the subnet name, CIDR block as per your requirement.
resource "aws_subnet" "Private_Subnet2" {
  vpc_id                  = aws_vpc.Terraform_VPC.id
  cidr_block              = "10.10.50.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "ap-south-1b"
  tags = {
    Name = "Private Subnet1"
  }
} # end resource


######################### Create Public Route Table #########################

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
  subnet_id      = aws_subnet.Public_Subnet.id
  route_table_id = aws_route_table.Terraform_route_table.id
} # end resource


######################### Instance Security Group ###########################

# Create the Security Group for instances.
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


###################### RDS Security Group ##########################

# Create the Security Group for DataBase Instance.
resource "aws_security_group" "RDS_SG" {
  vpc_id      = aws_vpc.Terraform_VPC.id
  name        = "RDS Security Group"
  description = "RDS Security Group"

  # allow ingress of port 5432
  ingress {
    cidr_blocks = ["10.10.10.0/24"]
    from_port   = 5432
    to_port     = 5432
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
    Name        = "RDS Security Group"
    Description = "RDS Security Group"
  }
} # end resource


################ EC2 Instance ##############################

# Launch EC2 instance in subnet 1.
resource "aws_instance" "Terraform_instance1" {
  ami             = "ami-005956c5f0f757d37"
  instance_type   = "t2.micro"
  key_name        = "mumbai"
  subnet_id       = aws_subnet.Public_Subnet.id
  security_groups = ["${aws_security_group.Terraform_SG.id}"]
  tags = {
    Name = "Terraform_Instance"
  }
}


################ Create SubnetGroup for RDS instance.  ##############

resource "aws_db_subnet_group" "rds-private-subnet" {
  name       = "rds-private-subnet-group"
  subnet_ids = [aws_subnet.Private_Subnet1.id, aws_subnet.Private_Subnet2.id]
}


################ Lauch RDS instance.  ##############

resource "aws_db_instance" "RDS_PGSQL" {
  allocated_storage      = 5
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "11.5"
  instance_class         = "db.t2.micro"
  name                   = "testdb"
  username               = "postgres"
  password               = "myserver123"
  parameter_group_name   = "default.postgres11"
  db_subnet_group_name   = aws_db_subnet_group.rds-private-subnet.name
  vpc_security_group_ids = ["${aws_security_group.RDS_SG.id}"]
  multi_az               = true
  skip_final_snapshot    = true
}

################# Databse Login #################

# 1: Once the Cloud formation completed, login to your EC2 instance. Install postgersql package. (#yum install postgresql).
# 2: Now go to RDS in Managemnet console. Selcet the newly cerated Database. Note down the Endpoint.
# 3: Loing to database using Endpoint.   #psql -h <Endpoint> -p 5432 -U  <Database user> 
# eg.  #psql -h mydb.asevdfefrapkv.ap-south-1.rds.amazonaws.com -p 5432 -U postgres 
# 4: Enter the password. And access the database
