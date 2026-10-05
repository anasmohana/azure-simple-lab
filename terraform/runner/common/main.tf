# Layer 3 - runner: private self-hosted CI runner VM in the runner subnet.
# Why: once Key Vault/Storage/AKS API are private, GitHub-hosted runners can't reach them.
# Needs layers bootstrap + network. Disabled in the lab to avoid VM cost.

data "azurerm_subnet" "runner" {
  name                 = "${local.name_prefix}-runner-snet"
  virtual_network_name = local.vnet_name
  resource_group_name  = local.network_rg_name
}

resource "azurerm_user_assigned_identity" "runner" {
  count               = var.enabled ? 1 : 0
  name                = "${local.name_prefix}-runner-id"
  location            = var.location_name
  resource_group_name = local.resource_group_name
  tags                = local.tags
}

resource "azurerm_network_interface" "runner" {
  count               = var.enabled ? 1 : 0
  name                = "${local.name_prefix}-runner-nic"
  location            = var.location_name
  resource_group_name = local.resource_group_name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.runner.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "runner" {
  count                           = var.enabled ? 1 : 0
  name                            = "${local.name_prefix}-runner"
  location                        = var.location_name
  resource_group_name             = local.resource_group_name
  size                            = var.vm_size
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.runner[0].id]
  custom_data                     = filebase64("${path.module}/cloud-init.yaml")
  tags                            = local.tags

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.admin_ssh_public_key
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.runner[0].id]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  lifecycle {
    precondition {
      condition     = var.admin_ssh_public_key != ""
      error_message = "admin_ssh_public_key is required when enabled = true."
    }
  }
}
