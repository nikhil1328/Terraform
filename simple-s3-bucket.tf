### Wednesday May 27 2020 20:50 IST 
## Purpose ## Terraform template to Create S3 bucket. ##
## Created by Nikhil Kulkarni ###

#########################################################################################################################

provider "aws" {
  version = "~> 2.0"
  access_key = access_key  # If you have already configured AWS-CLI then this is not required.
  secret_key = secret_key  # If you have already configured AWS-CLI then this is not required.
  region = "ap-south-1"
}

resource "aws_s3_bucket" "My_Bucket" {
  bucket = "my-terraform-bucket"  #This bucket name must be unique. 
  acl = "private"
  versioning {
    enabled = true
  }

  tags = {
    Name = "my-test-s3-terraform-bucket"
  }

}
