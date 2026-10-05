# Naming convention shared by every layer. Layers find each other by name via data sources,
# not by reading each other's state, so each layer can be planned/applied independently.
locals {
  tags = merge(var.base_tags, var.tags, { environment = var.environment })

  name_prefix         = "${var.prefix}-${var.environment}"
  resource_group_name = "${local.name_prefix}-rg"     # owned by bootstrap
  network_rg_name     = "${local.name_prefix}-net-rg" # owned by network
  vnet_name           = "${local.name_prefix}-vnet"
  log_analytics_name  = "${local.name_prefix}-law"
  aks_name            = "${local.name_prefix}-aks"
}
