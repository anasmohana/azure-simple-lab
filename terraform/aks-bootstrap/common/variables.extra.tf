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

variable "gitops_repo_url" {
  description = "Git repo Flux syncs from (public, contains only non-sensitive manifests)"
  type        = string
  default     = "https://github.com/anasmohana/azure-simple-lab-gitops"
}

variable "gitops_branch" {
  type    = string
  default = "main"
}
