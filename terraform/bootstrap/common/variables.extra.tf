variable "alert_email" {
  description = "Receiver for the action group"
  type        = string
}

variable "purge_protection" {
  description = "Key Vault purge protection. On for prd, off for dev so the lab can be destroyed and recreated."
  type        = bool
  default     = false
}

variable "allow_aks_subnet" {
  description = "Let the AKS subnet reach the Key Vault through its service endpoint. Needs the network layer applied first, so apply bootstrap again after network on a fresh build."
  type        = bool
  default     = false
}
