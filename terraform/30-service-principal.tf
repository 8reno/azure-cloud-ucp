resource "azuread_application" "docker" {
  name                 = "sp-docker-cloudcontroller"
}

resource "random_password" "sp_docker" {
  length = 32
  special = true
  keepers = {
    # Generate a new password only when a new deployment is defined
    deployment = azuread_service_principal.docker.display_name
  }
}

resource "azuread_service_principal" "docker" {
  application_id       = azuread_application.docker.application_id
}

resource "azuread_service_principal_password" "docker" {
  service_principal_id = azuread_service_principal.docker.id
  value                = random_password.sp_docker.result
  end_date             = "2299-12-31T00:00:00Z"
}

resource "azurerm_role_assignment" "ra_network" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azuread_service_principal.docker.id
}

resource "azurerm_role_assignment" "ra_docker" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.docker.id
}

