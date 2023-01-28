terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
     # version = "~> 3.27"
    }
  }
  #required_version = ">= 0.14.9"
}

provider "aws" {
  region  = var.aws_region #"us-east-1"
  profile = "default"
  default_tags {
    tags = {
      Owner = var.owner_tag
    }
  }
}
