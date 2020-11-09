provider azurerm {
  version = "~> 2.25"
  subscription_id         = var.subscription_id
  client_id               = var.client_id
  client_secret           = var.client_secret
  tenant_id               = var.tenant_id
  features {}
}

provider "azuread" {
  version                 = "~> 0.11.0"
  subscription_id         = var.subscription_id
  client_id               = var.client_id
  client_secret           = var.client_secret
  tenant_id               = var.tenant_id
}

provider "random" {
  version                 = "~> 2.2.0"
}
