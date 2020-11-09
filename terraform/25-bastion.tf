resource "azurerm_public_ip" "bastion" {
  name                              = "bastion"
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.public.name
  allocation_method                 = "Static"
  sku                               = "Standard"
}

resource "azurerm_network_security_group" "bastion" {
  name                              = "bastion"
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.rg.name

  security_rule {
    name                            = "Permit-SSH"
    priority                        = 100
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "Tcp"
    source_port_range               = "*"
    destination_port_range          = "22"
    source_address_prefixes         = var.permitted_source_addresses
    destination_address_prefix      = "VirtualNetwork"
  }

  security_rule {
    name                            = "Permit-Gateway"
    priority                        = 120
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "*"
    source_port_range               = "*"
    destination_port_range          = "*"
    source_address_prefix           = "VirtualNetwork"
    destination_address_prefix      = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                    = azurerm_subnet.bastion.id
  network_security_group_id    = azurerm_network_security_group.bastion.id
}

resource "azurerm_network_interface" "bastion" {
  name                              = "bastion-nic-01"
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.rg.name
  enable_ip_forwarding              = false

  ip_configuration {
    name                            = "bastion-ipconfig"
    subnet_id                       = azurerm_subnet.bastion.id
    private_ip_address_allocation   = "Dynamic"
    primary                         = true
    public_ip_address_id            = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_virtual_machine" "bastion" {
  name                              = "bastion"
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.rg.name
  network_interface_ids             = [ azurerm_network_interface.bastion.id ]
  vm_size                           = var.bastion_compute_sku

  delete_os_disk_on_termination     = true
  delete_data_disks_on_termination  = true

  storage_image_reference {
    publisher                       = "Canonical"
    offer                           = "UbuntuServer"
    sku                             = "18.04-LTS"
    version                         = "latest"
  }

  storage_os_disk {
    name                            = "bastion-osdisk"
    caching                         = "ReadWrite"
    create_option                   = "FromImage"
    managed_disk_type               = "Standard_LRS"
  }

  os_profile {
    computer_name                   = "bastion"
    admin_username                  = var.admin_username
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path                          = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data                      = file(var.admin_public_key_file)
    }
  }
}
