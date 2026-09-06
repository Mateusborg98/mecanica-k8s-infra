output "cluster_name" {
  description = "Nome do cluster EKS."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN do cluster EKS."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint privado da API do Kubernetes."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "Versão do Kubernetes utilizada pelo EKS."
  value       = aws_eks_cluster.this.version
}

output "cluster_security_group_id" {
  description = "Security Group criado pelo EKS para o cluster."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_group_name" {
  description = "Nome do Managed Node Group da aplicação."
  value       = aws_eks_node_group.application.node_group_name
}
