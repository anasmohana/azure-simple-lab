module "runner" {
  source = "../common"

  environment          = "dev"
  enabled              = var.enabled
  admin_ssh_public_key = var.admin_ssh_public_key

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

variable "admin_ssh_public_key" {
  description = "Public key for break-glass SSH (required when enabled = true)"
  type        = string
  default     = ""
}
