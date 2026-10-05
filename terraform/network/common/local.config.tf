locals {
  # One map drives subnets; add a subnet here and the module loop creates it.
  subnets = {
    runner = { cidr = cidrsubnet(var.address_space, 8, 1), nsg = "default" }
    pep    = { cidr = cidrsubnet(var.address_space, 8, 2), nsg = "default" }
    aks    = { cidr = cidrsubnet(var.address_space, 6, 1), nsg = "aks" } # /22 for nodes
  }

  private_dns_zones = {
    blob     = "privatelink.blob.core.windows.net"
    keyvault = "privatelink.vaultcore.azure.net"
  }

  nsgs = {
    default = {
      allow_https_in = {
        name                       = "allow-https-in"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
      }
      deny_all_in = {
        name                       = "deny-all-in"
        priority                   = 4000
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    }
    aks = {
      allow_vnet_in = {
        name                       = "allow-vnet-in"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
      }
      allow_lb_in = {
        name                       = "allow-azure-lb-in"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "AzureLoadBalancer"
        destination_address_prefix = "*"
      }
      deny_all_in = {
        name                       = "deny-all-in"
        priority                   = 4000
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    }
  }
}
