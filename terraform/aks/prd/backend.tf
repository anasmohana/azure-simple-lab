# Partial config: resource_group_name and storage_account_name are passed with
# -backend-config in CI. One state file per layer per environment, locked via blob lease.
terraform {
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "aks-prd.tfstate"
    use_azuread_auth = true
    use_oidc         = true
  }
}
