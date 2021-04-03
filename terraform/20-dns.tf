resource "azurerm_private_dns_zone" "vnet" {
    name                             = var.dns_zone_name
    resource_group_name              = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
    name                             = "${var.dns_zone_name}-vnet-link"
    resource_group_name              = azurerm_resource_group.rg.name
    private_dns_zone_name            = azurerm_private_dns_zone.vnet.name
    virtual_network_id               = azurerm_virtual_network.vnet.id
    registration_enabled             = "true"
}

resource "azurerm_private_dns_a_record" "adfs" {
    name                             = "adfs"
    zone_name                        = azurerm_private_dns_zone.vnet.name
    resource_group_name              = azurerm_resource_group.rg.name
    ttl                              = 300
    records                          = [ azurerm_public_ip.adfs.ip_address ]
    depends_on                       = [ azurerm_private_dns_zone_virtual_network_link.vnet_link ]
}

resource "azurerm_private_dns_a_record" "ucp" {
    name                             = "ucp"
    zone_name                        = azurerm_private_dns_zone.vnet.name
    resource_group_name              = azurerm_resource_group.rg.name
    ttl                              = 300
    records                          = [ azurerm_lb.ucp-int-lb.private_ip_address ]
    depends_on                       = [ azurerm_private_dns_zone_virtual_network_link.vnet_link ]
}

