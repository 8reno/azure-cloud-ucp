resource "azurerm_windows_virtual_machine" "adfs" {
  name                = "adfs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  size                = var.windows_compute_sku
  admin_username      = var.windows_admin_username 
  admin_password      = var.windows_admin_password 
  
  network_interface_ids = [
    azurerm_network_interface.adfs.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "adfs" {
  name                = "adfs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "adfs"
    subnet_id                     = azurerm_subnet.bastion.id
    private_ip_address_allocation = "Dynamic"
    primary                         = true
    public_ip_address_id            = azurerm_public_ip.adfs.id
  }
}

resource "azurerm_public_ip" "adfs" {
  name                              = "adfs"
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.public.name
  allocation_method                 = "Static"
  sku                               = "Standard"
}

resource "azurerm_network_security_rule" "permit-rdp" {
    name                            = "Permit-RDP"
    priority                        = 110
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "*"
    source_port_range               = "*"
    destination_port_range          = "3389"
    source_address_prefixes         = var.permitted_source_addresses
    destination_address_prefix      = "*"
    resource_group_name             = azurerm_resource_group.rg.name
    network_security_group_name     = azurerm_network_security_group.bastion.name
}

resource "azurerm_network_security_rule" "permit-https" {
    name                            = "Permit-HTTPS"
    priority                        = 500
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "*"
    source_port_range               = "*"
    destination_port_range          = "443"
    source_address_prefixes         = var.permitted_source_addresses
    destination_address_prefix      = "*"
    resource_group_name             = azurerm_resource_group.rg.name
    network_security_group_name     = azurerm_network_security_group.bastion.name
}

