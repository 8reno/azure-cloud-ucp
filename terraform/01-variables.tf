variable "subscription_id" {}
variable "tenant_id" {} 
variable "client_id" {}
variable "client_secret" {}

variable "location" {}
variable "resource_group" {}

variable "manager_image_id" {}
variable "worker_image_id" {}
variable "admin_username" {}
variable "admin_public_key_file" {}

variable "azure_ip_count" {}
variable "ucp_version" {}

variable "bastion_compute_sku" {}
variable "manager_compute_sku" {}
variable "manager_vmss_count" {}

variable "worker_compute_sku" {}
variable "worker_vmss_count" {}

variable "permitted_source_addresses" { type = list }

variable "windows_compute_sku" {}
variable "windows_admin_password" {}
variable "windows_admin_username" {}

variable "external_ucp_lb" {} 

variable "dns_zone_name" {}

variable "ucp_public_ip_domain_label" {}
