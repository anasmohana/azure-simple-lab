module "aks_bootstrap" {
  source = "../common"

  environment = "dev"
  enabled     = var.enabled

  tags = {
    project = "azure-simple-lab"
    owner   = "platform"
  }
}


variable "enabled" {
  description = "Deploy this layer. Off by default; the pipeline can pass -var enabled=true."
  type        = bool
  default     = false
}
