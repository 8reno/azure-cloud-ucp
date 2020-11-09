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

variable "bastion_compute_sku" {}
variable "manager_compute_sku" {}
variable "worker_compute_sku" {}

variable "permitted_source_addresses" { type = list }
