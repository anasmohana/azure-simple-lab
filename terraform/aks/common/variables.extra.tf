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

variable "node_vm_size" {
  description = "Default pool VM size. Standard_B2ms: 2 vCPU / 8 GB, the cheapest size with quota in the lab subscription."
  type        = string
  default     = "Standard_B2ms"
}

variable "node_min_count" {
  type    = number
  default = 1
}

variable "node_max_count" {
  type    = number
  default = 2
}

variable "availability_zones" {
  description = "Zones for the default pool. Empty in the lab; [\"1\",\"2\",\"3\"] in production."
  type        = list(string)
  default     = []
}

variable "user_pool_enabled" {
  description = "Add a separate user node pool. Off in the lab (single default pool)."
  type        = bool
  default     = false
}

variable "azure_policy_enabled" {
  description = "Azure Policy add-on (extra pods). Off in the small lab cluster."
  type        = bool
  default     = false
}
