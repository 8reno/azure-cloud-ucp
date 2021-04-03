resource "azurerm_lb" "ucp-int-lb" {
  name                            = "ucp"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  sku                             = "Standard"

  frontend_ip_configuration {
    name                          = "ucp-ipconfig"
    subnet_id                     = azurerm_subnet.docker.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.docker.address_prefix, -2)
  }
}

# load Balancer Backend Pools
resource "azurerm_lb_backend_address_pool" "ucp-int-pool" {
  name                            = "ucp-managers"
  resource_group_name             = azurerm_resource_group.rg.name
  loadbalancer_id                 = azurerm_lb.ucp-int-lb.id
}

resource "azurerm_lb_probe" "ucp-int-probe-https" {
  resource_group_name             = azurerm_resource_group.rg.name
  loadbalancer_id                 = azurerm_lb.ucp-int-lb.id
  name                            = "HTTPS"
  protocol                        = "tcp"
  port                            = "443"
  interval_in_seconds             = 5
  number_of_probes                = 2
}

resource "azurerm_lb_probe" "ucp-int-probe-k8s" {
  resource_group_name             = azurerm_resource_group.rg.name
  loadbalancer_id                 = azurerm_lb.ucp-int-lb.id
  name                            = "K8S"
  protocol                        = "tcp"
  port                            = "6443"
  interval_in_seconds             = 5
  number_of_probes                = 2
}

# Load Balancer Publishing Rules
resource "azurerm_lb_rule" "ucp-int-https" {
  resource_group_name             = azurerm_resource_group.rg.name
  loadbalancer_id                 = azurerm_lb.ucp-int-lb.id
  name                            = "ucp-https"
  protocol                        = "tcp"
  frontend_port                   = "443"
  backend_port                    = "443"
  frontend_ip_configuration_name  = "ucp-ipconfig"
  enable_floating_ip              = false
  backend_address_pool_id         = azurerm_lb_backend_address_pool.ucp-int-pool.id
  idle_timeout_in_minutes         = 5
  probe_id                        = azurerm_lb_probe.ucp-int-probe-https.id
}

resource "azurerm_lb_rule" "ucp-int-k8s" {
  resource_group_name             = azurerm_resource_group.rg.name
  loadbalancer_id                 = azurerm_lb.ucp-int-lb.id
  name                            = "ucp-k8s"
  protocol                        = "tcp"
  frontend_port                   = "6443"
  backend_port                    = "6443"
  frontend_ip_configuration_name  = "ucp-ipconfig"
  enable_floating_ip              = false
  backend_address_pool_id         = azurerm_lb_backend_address_pool.ucp-int-pool.id
  idle_timeout_in_minutes         = 5
  probe_id                        = azurerm_lb_probe.ucp-int-probe-k8s.id
}


# Public Load Balancer Resources
# Public IPs
resource "azurerm_public_ip" "ucplb" {
  count                           = var.external_ucp_lb ? 1 : 0
  name                            = "ucp-external"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  domain_name_label               = var.ucp_public_ip_domain_label
  allocation_method               = "Static"
  sku                             = "Standard"
}

# Public UCP Load Balancer
resource "azurerm_lb" "ucp-ext-lb" {
  count                           = var.external_ucp_lb ? 1 : 0
  name                            = "ucp-external"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  sku                             = "Standard"

  frontend_ip_configuration {
    name                          = "ucp-ipconfig"
    public_ip_address_id          = azurerm_public_ip.ucplb[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "ucp-ext-pool" {
  count                           = var.external_ucp_lb ? 1 : 0
  name                            = "UCP-MANAGERS"
  resource_group_name             = azurerm_resource_group.rg.name
  loadbalancer_id                 = azurerm_lb.ucp-ext-lb[count.index].id
}

resource "azurerm_lb_probe" "ucp-ext-probe-https" {
  count                           = var.external_ucp_lb ? 1 : 0
  resource_group_name             = azurerm_resource_group.rg.name
  loadbalancer_id                 = azurerm_lb.ucp-ext-lb[count.index].id
  name                            = "HTTPS"
  protocol                        = "tcp"
  port                            = "443"
  interval_in_seconds             = 5
  number_of_probes                = 2
}

resource "azurerm_lb_rule" "ucp-ext-https" {
  count                           = var.external_ucp_lb ? 1 : 0
  resource_group_name             = azurerm_resource_group.rg.name
  loadbalancer_id                 = azurerm_lb.ucp-ext-lb[count.index].id
  name                            = "UCP-HTTPS"
  protocol                        = "tcp"
  frontend_port                   = "443"
  backend_port                    = "443"
  frontend_ip_configuration_name  = "ucp-ipconfig"
  enable_floating_ip              = false
  backend_address_pool_id         = azurerm_lb_backend_address_pool.ucp-ext-pool[count.index].id
  idle_timeout_in_minutes         = 5
  probe_id                        = azurerm_lb_probe.ucp-ext-probe-https[count.index].id
}
