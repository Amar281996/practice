terraform {
  
  required_version = "> 0.8.0"
}
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

resource "null_resource" "CSI_deployments" {
  triggers = {
    content = "${null_resource.ASCP_deployment.id}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ../My_service/CSI_driver --recursive"
  }
  
}

resource "null_resource" "nginx_deployment" {
  triggers = {
    content = "${null_resource.CSI_deployments.id}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ../My_service/nginx --recursive"
  }
  
}


resource "null_resource" "sm" {
  triggers = {
    content = "${null_resource.nginx_deployment.id}"
  }
  provisioner "local-exec" {
    command = "kubectl -n production exec -it nginx-deployment-email-0 -- cat /mnt/api-token/secret-token"
  }
}

resource "null_resource" "sme" {
  triggers = {
    content = "${null_resource.sm.id}"
  }
  provisioner "local-exec" {
    command = "kubectl -n production exec -it nginx-deployment-event-0 -- cat /mnt/api-token/secret-token"
  }
}

resource "null_resource" "csi_installation" {
  triggers = {
    content = "${null_resource.sme.id}"
  }
  provisioner "local-exec" {
    command = "kubectl get csidrivers.storage.k8s.io"
    
  }
}





