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

