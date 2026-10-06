module "aks" {
  source = "../common"

  environment          = "dev"
  enabled              = var.enabled
  authorized_ip_ranges = var.authorized_ip_ranges

  tags = {
    project = "azure-simple-lab"
    owner   = "platform"
  }
}


variable "enabled" {
  description = "Deploy the cluster."
  type        = bool
  default     = true
}

variable "authorized_ip_ranges" {
  type    = list(string)
  default = []
}
