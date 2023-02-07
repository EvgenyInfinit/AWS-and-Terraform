terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile = "evgy-profile"
  region  = "us-east-1"
  
  default_tags {
    tags = {
      owner   = var.owner_tag
      Purpose = var.purpose_tag
    }
  }
}


# WORK IN PROGRESS !!!!
terraform {
  backend "s3" {
    #bucket = "mybucket"
    bucket  = "evgy-remote-state-terraform"
    #key    = "path/to/my/key"
    key     = "backend.tfstate"
    region = "us-east-1"
    #profile = "evgy-profile"
  }
}