terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.75.2"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      #version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      #version = "~> 2.0"
    }

  }
}
provider "aws" {
   profile = "default"
   region  = var.region
}

data "aws_eks_cluster_auth" "myeks" {
  name = aws_eks_cluster.eks.name
}
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.myeks.token
    
  }
}
data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "./terraform.tfstate"
  }
}

provider "kubernetes" {

  experiments {
      manifest_resource = true
   }
  host                   = "${aws_eks_cluster.eks.endpoint}"
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.eks.name
    ]
  }
}