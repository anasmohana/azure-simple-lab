variable "enabled" {
  description = "Deploy the cluster. Off by default: design is reviewable, no idle cluster cost."
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "admin_group_object_ids" {
  description = "Entra groups with cluster-admin (Azure RBAC for Kubernetes handles the rest)"
  type        = list(string)
  default     = []
}

variable "authorized_ip_ranges" {
  description = "CIDRs allowed to reach the public API server, e.g. [\"203.0.113.7/32\"]. Empty = unrestricted (not for prod)."
  type        = list(string)
  default     = []
}
