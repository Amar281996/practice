locals {
    oidc_provider = replace("${aws_eks_cluster.eks.identity[0].oidc[0].issuer}","https://","oidc-provider/")
    oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider}"
}



# Install helm chart for CSI Secret Storage Driver
resource "helm_release" "secret_storage_csi_driver" {
  chart      = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  name       = "secrets-store-csi-driver"
  namespace  = "kube-system"
  version    = "1.0.1"
  atomic     = true

  set {
    name  = "linux.tolerations[0].operator"
    value = "Exists"
  }

  set {
    name  = "linux.tolerations[0].effect"
    value = "NoSchedule"
  }
}

# Stuff for AWS Secret Provisioner
#

resource "kubernetes_service_account" "csi_secrets_store_provider_aws" {
  metadata {
    name      = "csi-secrets-store-provider-aws"
    namespace = helm_release.secret_storage_csi_driver.metadata[0].namespace
    annotations = {
      "eks.amazonaws.com/role-arn" : aws_iam_role.secret_role.arn
    }
  }
}

resource "kubernetes_cluster_role" "csi_secrets_store_provider_aws" {
  metadata {
    name = "csi-secrets-store-provider-aws-cluster-role"
  }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts/token"]
    verbs      = ["create"]
  }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["get"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "csi_secrets_store_provider_aws" {
  metadata {
    name = "csi-secrets-store-provider-aws-cluster-rolebinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.csi_secrets_store_provider_aws.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.csi_secrets_store_provider_aws.metadata[0].name
    namespace = kubernetes_service_account.csi_secrets_store_provider_aws.metadata[0].namespace
  }
}

resource "kubernetes_daemonset" "csi_secrets_store_provider_aws" {
  metadata {
    name      = "csi-secrets-store-provider-aws"
    namespace = "kube-system"
    labels = {
      app = "csi-secrets-store-provider-aws"
    }
  }
  spec {
    strategy {
      rolling_update {}
    }
    selector {
      match_labels = {
        app = "csi-secrets-store-provider-aws"
      }
    }
    template {
      metadata {
        labels = {
          app = "csi-secrets-store-provider-aws"
        }
        annotations = {}
      }
      spec {
        service_account_name = kubernetes_service_account.csi_secrets_store_provider_aws.metadata[0].name
        host_network         = true
        container {
          name              = "provider-aws-installer"
          image             = "public.ecr.aws/aws-secrets-manager/secrets-store-csi-driver-provider-aws:1.0.r2-2021.08.13.20.34-linux-amd64"
          image_pull_policy = "Always"
          args = [
            "--provider-volume=/etc/kubernetes/secrets-store-csi-providers"
          ]
          resources {
            requests = {
              cpu    = "50m"
              memory = "100Mi"
            }
            limits = {
              cpu    = "50m"
              memory = "100Mi"
            }
          }
          volume_mount {
            mount_path = "etc/kubernetes/secrets-store-csi-providers"
            name       = "providervol"
          }
          volume_mount {
            mount_path        = "/var/lib/kubelet/pods"
            mount_propagation = "HostToContainer"
            name              = "mountpoint-dir"
          }
        }
        volume {
          name = "providervol"
          host_path {
            path = "/etc/kubernetes/secrets-store-csi-providers"
          }
        }
        volume {
          name = "mountpoint-dir"
          host_path {
            path = "/var/lib/kubelet/pods"
            type = "DirectoryOrCreate"
          }
        }
        node_selector = {
          "kubernetes.io/os" = "linux"
        }
        toleration {
          operator = "Exists"
          effect   = "NoSchedule"
        }
      }
    }
  }
}

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = "app"
  }
}

resource "aws_iam_role" "eks_iamserviceaccount_app" {
  name               = "eks-${aws_eks_cluster.eks.id}-app-secret-iamserviceaccount"
  assume_role_policy = data.aws_iam_policy_document.assume_role_iamserviceaccount.json
  managed_policy_arns = [
    aws_iam_policy.secret_storage_class1.arn
  ]
}

data "aws_iam_policy_document" "assume_role_iamserviceaccount" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values = [
        format(
          "system:serviceaccount:%s:%s",
          kubernetes_namespace_v1.app.metadata[0].name,
          "secret"
        )
      ]
    }

    principals {
      identifiers = [local.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

data "aws_iam_policy_document" "secrets_storage_csi" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "kms:Decrypt"
    ]
    resources = [
      aws_secretsmanager_secret.event.arn,
      aws_secretsmanager_secret.email.arn,
      aws_kms_key.app.arn
    ]
  }
}
resource "aws_iam_policy" "secret_storage_class1" {
  policy = data.aws_iam_policy_document.secrets_storage_csi.json
  name   = "app-secret-access-to-event"
}
resource "aws_iam_policy" "secret_storage_class2" {
  policy = data.aws_iam_policy_document.secrets_storage_csi.json
  name   = "app-secret-access-to-email"
}
resource "kubernetes_service_account_v1" "kubesa" {
  metadata {
    name      = "secret"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = {
     "app.kubernetes.io/name" = "secret"
     "app.kubernetes.io/instance" = "secret"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_iamserviceaccount_app.arn
    }
  }
}
resource "aws_kms_key" "app" {
  deletion_window_in_days = 7
  description             = "app sensitive data encryption key for secret"
}

resource "aws_kms_alias" "app" {
  target_key_id = aws_kms_key.app.id
  name          = "alias/app/secret"
}
resource "kubernetes_manifest" "secret-provider-class" {
depends_on = [
    aws_eks_cluster.eks
  ]
  provider = kubernetes
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      namespace = kubernetes_namespace_v1.app.metadata[0].name
      name      = "secret"
    }
    spec = {
      provider = "aws"
      parameters = {
        objects = yamlencode([
          {
            objectName  = aws_secretsmanager_secret.event.id
            objectType  = "secretsmanager"
            objectAlias = "sensitive"
          },
          {

            objectName  = aws_secretsmanager_secret.email.id
            objectType  = "secretsmanager"
            objectAlias = "sensitive"
          }

        ])
      }
    }
  }
}

resource "kubernetes_pod_v1" "app" {
  metadata {
    name      = "event"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = {
     "app.kubernetes.io/name" = "secret"
     "app.kubernetes.io/instance" = "secret"
    }
  }
  spec {
    container {
      name = "secret-event"
      security_context {
        capabilities {
          drop = [
            "ALL"
          ]
        }
        privileged                = false
        read_only_root_filesystem = true
        run_as_group              = "65534"
        run_as_non_root           = true
        run_as_user               = "65534"
      }
      image             = "nginx:latest"
      volume_mount {
        mount_path = "/mnt/api-token"
        name       = "sensitive"
      }
    }
    security_context {
      fs_group        = "65534"
      run_as_group    = "65534"
      run_as_non_root = true
      run_as_user     = "65534"
    }
    service_account_name = kubernetes_service_account_v1.kubesa.metadata[0].name
    volume {
      name = "sensitive"
      csi {
        driver    = "secrets-store.csi.k8s.io"
        read_only = true
        volume_attributes = {
          secretProviderClass = kubernetes_manifest.secret-provider-class.manifest.metadata.name
        }
      }
    }
  }
}
