terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.75.2"
    }
    null = {
      source = "hashicorp/null"
      version = "3.1.1"
    }
  }
  
  
}


    provider "aws" {
   profile = "default"
   region  = var.region
}

provider "null" {
  # Configuration options
}


 
