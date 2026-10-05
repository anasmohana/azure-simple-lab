locals {
  keyvaults = {
    boot = {
      name                               = "kv-${var.prefix}-${var.environment}-${local.suffix}"
      resource_group_name                = azurerm_resource_group.this.name
      location_name                      = azurerm_resource_group.this.location
      enable_rbac_authorization          = true
      purge_protection_enabled           = var.purge_protection
      soft_delete_retention_days         = 7
      public_network_access_enabled      = true
      enable_monitor_diagnostic_setting  = true
      azurerm_log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
      network = {
        bypass         = "AzureServices"
        default_action = "Deny"
      }
      tags = local.tags
    }
  }
}
