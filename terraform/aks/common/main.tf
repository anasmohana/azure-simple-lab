# Layer 4 - aks: private, Entra-integrated cluster in the nodes subnet from the network layer.

data "azurerm_client_config" "current" {}

data "azurerm_log_analytics_workspace" "logs" {
  name                = local.log_analytics_name
  resource_group_name = local.resource_group_name
}

data "azurerm_subnet" "aks" {
  name                 = "${local.name_prefix}-aks-snet"
  virtual_network_name = local.vnet_name
  resource_group_name  = local.network_rg_name
}

module "aks" {
  source      = "git::https://github.com/anasmohana/terraform-modules.git//modules/aks?ref=a3daf2d82881f9aba947a82877faac6c7007602c"
  for_each    = var.enabled ? local.clusters : {}
  settings    = each.value
  diagnostics = {}
  base_tags   = local.tags
}
