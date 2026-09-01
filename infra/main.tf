locals {
  name = "mecanica-${var.environment}"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_eks_cluster" "this" {
  name     = local.name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  enabled_cluster_log_types = var.control_plane_log_types

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    subnet_ids = sort(data.aws_subnets.default.ids)

    endpoint_private_access = true
    endpoint_public_access  = false
  }

  lifecycle {
    precondition {
      condition     = length(data.aws_subnets.default.ids) >= 2
      error_message = "O EKS exige subnets em ao menos duas zonas de disponibilidade."
    }
  }
}

resource "aws_eks_access_entry" "administrator" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.cluster_admin_principal_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "administrator" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.administrator.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_node_group" "application" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.name}-application"
  node_role_arn   = var.node_role_arn
  subnet_ids      = sort(data.aws_subnets.default.ids)

  capacity_type  = "ON_DEMAND"
  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size_gib

  scaling_config {
    min_size     = var.node_min_size
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    precondition {
      condition = (
        var.node_min_size <= var.node_desired_size
        && var.node_desired_size <= var.node_max_size
      )
      error_message = "A escala deve respeitar: mínimo <= desejado <= máximo."
    }
  }

  depends_on = [aws_eks_access_policy_association.administrator]
}
