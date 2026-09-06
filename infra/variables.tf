variable "aws_region" {
  description = "Região AWS utilizada pelo cluster Kubernetes."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente de implantação."
  type        = string

  validation {
    condition     = contains(["homolog", "prod"], var.environment)
    error_message = "O ambiente deve ser homolog ou prod."
  }
}

variable "cluster_role_arn" {
  description = "ARN da role preexistente utilizada pelo control plane do EKS."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.cluster_role_arn))
    error_message = "Informe um ARN válido de role IAM."
  }
}

variable "node_role_arn" {
  description = "ARN da role preexistente utilizada pelos nós do EKS."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.node_role_arn))
    error_message = "Informe um ARN válido de role IAM."
  }
}

variable "cluster_admin_principal_arn" {
  description = "ARN da role preexistente autorizada a administrar o Kubernetes."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.cluster_admin_principal_arn))
    error_message = "Informe um ARN válido para o administrador do cluster."
  }
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes. Quando nula, a AWS escolhe uma versão suportada."
  type        = string
  default     = null
  nullable    = true
}

variable "excluded_availability_zones" {
  description = "Zonas da região que não oferecem suporte ao control plane do EKS."
  type        = set(string)
  default     = ["us-east-1e"]
}

variable "cluster_public_access_cidrs" {
  description = "Redes autorizadas a alcançar o endpoint público autenticado do EKS."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.cluster_public_access_cidrs : can(cidrnetmask(cidr))
    ])
    error_message = "Todos os valores devem ser blocos CIDR válidos."
  }
}

variable "node_instance_types" {
  description = "Tipos de instância permitidos no Managed Node Group."
  type        = list(string)
  default     = ["t3.small"]

  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "Informe ao menos um tipo de instância para os nós."
  }
}

variable "node_min_size" {
  description = "Quantidade mínima de nós."
  type        = number
  default     = 1

  validation {
    condition     = var.node_min_size >= 1
    error_message = "O cluster deve possuir ao menos um nó."
  }
}

variable "node_desired_size" {
  description = "Quantidade desejada de nós."
  type        = number
  default     = 1

  validation {
    condition     = var.node_desired_size >= 1
    error_message = "A quantidade desejada deve ser ao menos um nó."
  }
}

variable "node_max_size" {
  description = "Quantidade máxima de nós permitida pela escalabilidade."
  type        = number
  default     = 2

  validation {
    condition     = var.node_max_size >= 1
    error_message = "A quantidade máxima deve ser ao menos um nó."
  }
}

variable "node_disk_size_gib" {
  description = "Tamanho do disco de cada nó em GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.node_disk_size_gib >= 20
    error_message = "O disco de cada nó deve possuir ao menos 20 GiB."
  }
}

variable "control_plane_log_types" {
  description = "Tipos de logs do control plane enviados ao CloudWatch."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for log_type in var.control_plane_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Foi informado um tipo de log do EKS inválido."
  }
}
