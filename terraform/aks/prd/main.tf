module "aks" {
  source = "../common"

  environment          = "prd"
  enabled              = var.enabled
  authorized_ip_ranges = var.authorized_ip_ranges

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

variable "authorized_ip_ranges" {
  type    = list(string)
  default = []
}
