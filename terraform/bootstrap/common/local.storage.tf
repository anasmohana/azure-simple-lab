locals {
  storage_accounts = {
    data = {
      name                              = "st${var.prefix}${var.environment}${local.suffix}"
      resource_group_name               = azurerm_resource_group.this.name
      location                          = azurerm_resource_group.this.location
      account_replication_type          = var.environment == "prd" ? "GRS" : "LRS"
      allow_nested_items_to_be_public   = false
      enable_monitor_diagnostic_setting = true
      log_analytics_workspace_id        = azurerm_log_analytics_workspace.logs.id
      shared_access_key_enabled         = false # Entra ID auth only
      public_network_access_enabled     = true  # firewall denies by default; real prod: false + private endpoint
      network_rules = {
        default_action = "Deny"
        bypass         = ["AzureServices"]
      }
      blob_properties = {
        versioning_enabled = true
        delete_retention_policy = {
          delete_retention_policy = 7
        }
      }
      tags = local.tags
    }
  }
}
