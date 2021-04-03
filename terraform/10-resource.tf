resource "azurerm_resource_group" "rg" {
  name                   = var.resource_group
  location               = var.location
}

resource "azurerm_resource_group" "public" {
  name                   = "public"
  location               = var.location
}

resource "azurerm_virtual_network" "vnet" {
    name                 = "vnet"
    location             = azurerm_resource_group.rg.location
    resource_group_name  = azurerm_resource_group.rg.name
    address_space        = [ "10.0.0.0/22" ]
}

resource "azurerm_subnet" "docker" {
    name                 = "docker"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [ "10.0.2.0/23" ]
}

resource "azurerm_subnet" "bastion" {
    name                 = "bastion"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [ "10.0.1.0/25" ]
}

resource "azurerm_subnet" "mgmt" {
    name                 = "mgmt"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [ "10.0.1.128/25" ]
}
  
