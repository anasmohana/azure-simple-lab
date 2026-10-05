# Layer 2 - network: VNet, NSGs, route table, subnets, private DNS zones.

resource "azurerm_resource_group" "net" {
  name     = local.network_rg_name
  location = var.location_name
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  location            = azurerm_resource_group.net.location
  resource_group_name = azurerm_resource_group.net.name
  address_space       = [var.address_space]
  tags                = local.tags
}

module "nsg" {
  source              = "git::https://github.com/anasmohana/terraform-modules.git//modules/network_security_group?ref=a3daf2d82881f9aba947a82877faac6c7007602c"
  for_each            = local.nsgs
  resource_group_name = azurerm_resource_group.net.name
  location            = azurerm_resource_group.net.location
  settings = {
    nsg_name = "${local.name_prefix}-${each.key}-nsg"
    tags     = local.tags
    nsg      = each.value
  }
}

module "route_table" {
  source              = "git::https://github.com/anasmohana/terraform-modules.git//modules/route_tables?ref=a3daf2d82881f9aba947a82877faac6c7007602c"
  resource_group_name = azurerm_resource_group.net.name
  location            = azurerm_resource_group.net.location
  base_tags           = local.tags
  settings = {
    name = "${local.name_prefix}-rt"
    tags = {}
  }
}

module "subnets" {
  source                    = "git::https://github.com/anasmohana/terraform-modules.git//modules/subnet_v2?ref=a3daf2d82881f9aba947a82877faac6c7007602c"
  for_each                  = local.subnets
  resource_group_name       = azurerm_resource_group.net.name
  existing_vnet_name        = azurerm_virtual_network.this.name
  network_security_group_id = module.nsg[each.value.nsg].id
  route_table_id            = module.route_table.id
  settings = {
    name              = "${local.name_prefix}-${each.key}-snet"
    address_prefixes  = [each.value.cidr]
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
  }
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.net.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = azurerm_private_dns_zone.this
  name                  = "${local.name_prefix}-${each.key}-link"
  resource_group_name   = azurerm_resource_group.net.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.tags
}
