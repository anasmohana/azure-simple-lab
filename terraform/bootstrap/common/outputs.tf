output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "storage_account_name" {
  value = module.storage_accounts["data"].name
}

output "key_vault_name" {
  value = module.keyvaults["boot"].name
}
