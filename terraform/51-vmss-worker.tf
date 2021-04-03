resource "azurerm_virtual_machine_scale_set" "worker" {
  name                = "worker"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  upgrade_policy_mode = "Manual"
  overprovision                      = false

  sku {
    name                             = var.worker_compute_sku
    tier                             = "Standard"
    capacity                         = var.worker_vmss_count
  }

  storage_profile_image_reference {
    id                              = var.worker_image_id
  }

  storage_profile_os_disk {
    name                            = ""
    create_option                   = "FromImage"
    caching                         = "ReadWrite"
    managed_disk_type               = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix            = "worker"
    admin_username                  = var.admin_username
    custom_data                     = data.template_cloudinit_config.cloudinitconfig.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path                          = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data                      = file(var.admin_public_key_file) 
    }
  }

  network_profile {
    name    = "primary"
    primary = true

    ip_configuration {
      name                                    = "worker-ipconfig"
      primary                                 = true
      subnet_id                               = azurerm_subnet.docker.id
    }

    dynamic "ip_configuration" {
      for_each = toset(range(var.azure_ip_count))
      iterator = nic
      content {
        name  = "k8s_ip${nic.value}"
        subnet_id  = azurerm_subnet.docker.id
        primary    = false
      }
    }
  }

}
