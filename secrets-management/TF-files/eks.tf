# Resource: aws_iam_role
resource "aws_iam_role" "my_eks" {
  # The name of the role
  name = "eks1"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "policy" {
  name        = "secret-policy"
  description = "A test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

  # The role the policy should be applied to
  role = "${aws_iam_role.my_eks.name}"
}

# Resource: aws_eks_cluster
resource "aws_eks_cluster" "eks" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
  role_arn = aws_iam_role.my_eks.arn

  
  version = "1.22"

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access = true

    #availability zones
    subnet_ids = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id,
      aws_subnet.private_1.id,
      aws_subnet.private_2.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy
  ]
}

/*output "kubeconfig-certificate" {
  value = aws_eks_cluster.eks.certificate_authority[0].data 
}*/
