module "aks_bootstrap" {
  source = "../common"

  environment = "dev"
  enabled     = var.enabled
  namespaces  = { website = "website" }

  tags = {
    project = "azure-simple-lab"
    owner   = "platform"
  }
}


variable "enabled" {
  description = "Deploy workload identities and Flux."
  type        = bool
  default     = true
}
