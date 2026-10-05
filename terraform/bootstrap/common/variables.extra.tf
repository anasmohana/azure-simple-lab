variable "alert_email" {
  description = "Receiver for the action group"
  type        = string
}

variable "purge_protection" {
  description = "Key Vault purge protection. On for prd, off for dev so the lab can be destroyed and recreated."
  type        = bool
  default     = false
}
