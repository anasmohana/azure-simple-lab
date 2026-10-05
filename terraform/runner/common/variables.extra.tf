variable "enabled" {
  description = "Deploy the self-hosted runner VM. Off by default: the lab runs on GitHub-hosted runners."
  type        = bool
  default     = false
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "admin_ssh_public_key" {
  description = "Public key for break-glass SSH from inside the VNet (no password auth, no public IP)"
  type        = string
  default     = ""
}
