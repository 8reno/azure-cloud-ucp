resource "azurerm_subnet_network_security_group_association" "docker" {
  subnet_id                    = azurerm_subnet.docker.id
  network_security_group_id    = azurerm_network_security_group.docker.id
}

resource "azurerm_network_security_group" "docker" {
  name                         = "docker"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "sn-docker-in-ssh" {
    name                       = "ssh"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = flatten([ var.permitted_source_addresses, azurerm_virtual_network.vnet.address_space] )
    destination_address_prefix = "VirtualNetwork"
    network_security_group_name = azurerm_network_security_group.docker.name
    resource_group_name         = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "docker-in-k8s" {
    name                       = "k8s"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefixes    = flatten([ var.permitted_source_addresses, azurerm_virtual_network.vnet.address_space ] )
    destination_address_prefix = "VirtualNetwork"
    network_security_group_name = azurerm_network_security_group.docker.name
    resource_group_name         = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "docker-in-https" {
    name                       = "https"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = flatten([ var.permitted_source_addresses, azurerm_virtual_network.vnet.address_space] )
    destination_address_prefix = "VirtualNetwork"
    network_security_group_name = azurerm_network_security_group.docker.name
    resource_group_name         = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "sn-docker-in-k8s-nodeports" {
    name                       = "k8s-nodeports"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "32768-35535"
    source_address_prefixes    = flatten([ var.permitted_source_addresses, azurerm_virtual_network.vnet.address_space] )
    destination_address_prefix = "VirtualNetwork"
    network_security_group_name = azurerm_network_security_group.docker.name
    resource_group_name         = azurerm_resource_group.rg.name
}


