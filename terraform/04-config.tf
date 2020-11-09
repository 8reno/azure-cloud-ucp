terraform {
  backend "azurerm" {
    storage_account_name = "{{ STATE_STORAGE_ACCOUNT_NAME }}"
    container_name       = "{{ STATE_STORAGE_CONTAINER_NAME }}"
    key                  = "{{ STATE_STORAGE_ACCESS_KEY_NAME }}"
    access_key           = "{{ STATE_STORAGE_ACCESS_KEY }}"
  }
}

