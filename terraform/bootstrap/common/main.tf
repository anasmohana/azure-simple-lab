# Layer 1 - bootstrap: resource group, logging, storage, key vault, alerting.
# Everything else in the platform builds on these.

data "azurerm_client_config" "current" {}

locals {
  # Short deterministic suffix so globally-unique names (storage, key vault) don't collide
  suffix = substr(md5(data.azurerm_client_config.current.subscription_id), 0, 5)
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location_name
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = local.log_analytics_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.5 # hard cap keeps the lab cheap
  tags                = local.tags
}

module "storage_accounts" {
  source    = "git::https://github.com/anasmohana/terraform-modules.git//modules/storage_account?ref=a3daf2d82881f9aba947a82877faac6c7007602c"
  for_each  = local.storage_accounts
  settings  = each.value
  base_tags = local.tags
}

module "keyvaults" {
  source        = "git::https://github.com/anasmohana/terraform-modules.git//modules/keyvault?ref=a3daf2d82881f9aba947a82877faac6c7007602c"
  for_each      = local.keyvaults
  settings      = each.value
  base_tags     = local.tags
  client_config = data.azurerm_client_config.current
}

# Native resource: the shared action_group module pins azurerm ~>3.33 and can't be used with 4.x
resource "azurerm_monitor_action_group" "this" {
  name                = "${local.name_prefix}-ag"
  resource_group_name = azurerm_resource_group.this.name
  short_name          = "labops"
  tags                = local.tags

  email_receiver {
    name                    = "oncall"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "storage_availability" {
  name                = "${local.name_prefix}-storage-availability"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [module.storage_accounts["data"].id]
  description         = "Storage availability below 99% (SLO burn signal)"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.tags

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}
