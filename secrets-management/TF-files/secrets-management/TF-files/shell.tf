
resource "null_resource" "eks_config" {
  triggers = {
    content = "${aws_iam_openid_connect_provider.cluster.id}"
  }
  
  provisioner "local-exec" {
          command = "aws eks --region us-west-1 update-kubeconfig --name eks --profile default"
          }
}



resource "null_resource" "ASCP_deployment" {
  triggers = {
    content = "${null_resource.eks_config.id}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ../My_service/ASCP_installer --recursive"
  }
  
}

resource "null_resource" "CSI_repo" {
  triggers = {
    content = "${null_resource.ASCP_deployment.id}"
  }

  provisioner "local-exec" {
    command = "helm repo add secrets-store-csi-driver1 https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  }

}
resource "null_resource" "CSI_driver" {
  triggers = {
    content = "${null_resource.CSI_repo.id}"
  }

  provisioner "local-exec" {
    command = "helm -n kube-system install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --set syncSecret.enabled=true --set enableSecretRotation=true --set rotationPollInterval=3600s"
  }

}

resource "null_resource" "nginx_deployment" {
  triggers = {
    content = "${null_resource.CSI_driver.id}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ../My_service/nginx --recursive"
  }
  
}


resource "null_resource" "secret_verification" {
  triggers = {
    content = "${null_resource.nginx_deployment.id}"
  }
  provisioner "local-exec" {
    command = "kubectl get all -n production"
  }
}


resource "null_resource" "csi_installation" {
  triggers = {
    content = "${null_resource.secret_verification.id}"
  }
  provisioner "local-exec" {
    command = "kubectl get csidrivers.storage.k8s.io"
    
  }
}





