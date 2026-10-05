variable "enabled" {
  description = "Create workload identities. Needs the aks layer deployed (OIDC issuer)."
  type        = bool
  default     = false
}

variable "namespaces" {
  description = "Namespace => service account pairs that get a federated Azure identity"
  type        = map(string)
  default     = { app = "api" }
}
