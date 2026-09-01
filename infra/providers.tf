provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "mecanica"
      Component   = "kubernetes"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
