# Subscription, tenant and client come from ARM_* environment variables
# (ARM_USE_OIDC=true in CI) so no identifiers are committed.
provider "azurerm" {
  storage_use_azuread = true
  features {}
}
