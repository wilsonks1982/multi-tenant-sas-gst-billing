terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}