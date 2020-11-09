resource "azurerm_route_table" "gateway" {
  name                          = "gateway"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  disable_bgp_route_propagation = false

  route {
      name                      = "Default"
      address_prefix            = "0.0.0.0/0"
      next_hop_type             = "VirtualAppliance"
      next_hop_in_ip_address    = azurerm_network_interface.bastion.private_ip_address
  }

}

resource "azurerm_subnet_route_table_association" "docker" {
  subnet_id                 = azurerm_subnet.docker.id
  route_table_id            = azurerm_route_table.gateway.id
}

