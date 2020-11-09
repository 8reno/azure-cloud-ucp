locals{

  cloud_init_vars = {
    tenant_id                   = var.tenant_id
    subscription_id             = var.subscription_id
    docker_resource_group       = azurerm_resource_group.rg.name
    vnet_region                 = azurerm_resource_group.rg.location
    docker_subnet_name          = azurerm_subnet.docker.name
    vnet_name                   = azurerm_virtual_network.vnet.name
    vnet_resourcegroup_name     = azurerm_virtual_network.vnet.resource_group_name
    docker_worker_scaleset_name = "worker"
    k8s_lb_name                 = "worker"
    k8s_lb_sku                  = "Standard"
    aad_client_id               = azuread_application.docker.application_id
    aad_client_secret           = random_password.sp_docker.result
    security_group_name         = azurerm_network_security_group.docker.name
  }

}

data "template_cloudinit_config" "cloudinitconfig" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("45-cloudconfig.tpl", local.cloud_init_vars)
  }
}

