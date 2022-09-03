# secrets-management
secrets-management


# Details

## Problem statement:
* We have few microservices. They need to read secrets in runtime. Recommended service is AWS secrets manager.

## Approach:
```
Use EKS (use recent version, v1.22) + Secrets Manager
- Use ASCP for our solution
- Retrieve the secrkubecets as file into EKS
- Use ASCP to Configure IAM (assume-role/policy) so that the respective microservice should be able to read specific secrets only


Notes:
- These services are running in EKS
```

## Sample data
```
Manually store 
- 'events_service_mysql_user_id'
- 'events_service_mysql_password'
- 'email_service_mysql_user_id'
- 'email_service_mysql_password'
 
Use your personal account 
```






## Steps for storing and retriving secrets from eks pod as a file:
Pre-requisites:
```````````````

 -aws cli
 -Iam authenticator
 -kubectl

1. Create Secret manager using terraform
    - declare secrets using variables

2. Create EKS Cluster using terraform
    -Create eks.tf config file and someother Tf files based on requirment
    -after cluster created update the kubeconfig using below command
         aws eks --region us-east-2 update-kubeconfig --name eks --profile default
    - To get svc using below command
           kubectl get svc
  
  2.1. Create eks_node_group 

3. Create IAM OIDC Provider for EKS
     -Copy OpenID Connect provider URL
     -Create Identety Provider - select OpenID Connect
     -Enter sts.amazonaws.com for Audience
4. Create IAM Role for a Kubernetes Service Account
      -web-identity
5. Associate an IAM Role with Kubernetes Service Account
    -Create nginx/namespace.yaml
    -Create nginx/service-account.yaml
         then apply all using kubectl apply -f filenames
6. install the Kubernetes Secrets Store CSI Driver
     - Create secrets-store-csi-driver/0-secretproviderclasses-crd.yaml
     -Create secrets-store-csi-driver/1-secretproviderclasspodstatuses-crd.yaml
        -kubectl apply -f secrets-store-csi-driver
     -Create secrets-store-csi-driver/2-service-account.yaml
     -Create secrets-store-csi-driver/3-cluster-role.yaml
     -Create secrets-store-csi-driver/4-cluster-role-binding.yaml
     -Create secrets-store-csi-driver/5-daemonset.yaml
     -Create secrets-store-csi-driver/6-csi-driver.yaml 
         then apply all using 
             kubectl apply -k [directory of Ymal files]
  
7. Install AWS Secrets & Configuration Provider (ASCP)
    -Create aws-provider-installer/0-service-account.yaml
    -Create aws-provider-installer/1-cluster-role.yaml
    -Create aws-provider-installer/2-cluster-role-binding.yaml
    -Create aws-provider-installer/3-daemonset.yaml
         then apply all using 
           kubectl apply -k  ASCP_installer
 
8. Create Secret Provider Class 
     -object will map the secrets in secret manager

9. Create Pod and copy the secrets files which we generated using null resource into pod
     - To login pod in interactive mode use below command
        kubectl exec -it podname -- /bash
                    or
        kubctl exec -it podname -- /bin/bash/
     - we need to copy the secrets files into pod using null resource
          kubectl cp ../filename podname:pod_dir
        
     - To verify the copied files we can use below command in null resource
        kubectl exec -it podname -- cat /opt/filename

10. automated execution of ymal files using null_resource
     -create a .tf config file for executing ymal files using null resource

11. wrote terratest for validating terraform code

     Go version used for terratesting
     - go1.19

          
