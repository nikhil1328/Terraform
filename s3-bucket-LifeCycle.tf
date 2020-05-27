## Wednesday May 27 2020 20:50 IST 
## Purpose ## Terraform template to S# bucket. ##
## Created by Nikhil Kulkarni ###

#########################################################################################################################
provider "aws" {
  version = "~> 2.0"
  access_key = access_key  # If you have already configured AWS-CLI then this is not required.
  secret_key = secret_key  # If you have already configured AWS-CLI then this is not required.
  region = "ap-south-1"
}

# Creation of S3 bucket.
resource "aws_s3_bucket" "My_Bucket" {
  bucket = "my-terraform-bucket-25052020"
  acl = "private"
  versioning {
    enabled = true
  }

  tags = {
    Name = "my-test-s3-terraform-bucket"
  }

# Add bucket life cycle rules.
  lifecycle_rule {
    enabled = true

    transition {
      days = 30 
      storage_class = "STANDARD_IA"
    }

    transition {
      days = 60
      storage_class = "GLACIER"
    }
  }
}

