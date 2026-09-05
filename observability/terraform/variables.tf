variable "environment" {
  description = "Ambiente monitorado pelo Datadog."
  type        = string
  validation {
    condition     = contains(["homolog", "prod"], var.environment)
    error_message = "O ambiente deve ser homolog ou prod."
  }
}
