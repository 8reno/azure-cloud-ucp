subscription_id   = "{{ AZURE_SUBSCRIPTION_ID }}"
tenant_id         = "{{ AZURE_TENANT_ID }}"
client_id         = "{{ AZURE_SERVICE_PRINCIPAL_CLIENT_ID }}"
client_secret     = "{{ AZURE_SERVICE_PRINCIPAL_CLIENT_SECRET }}""

location          = "{{ AZURE_LOCATION }}"
resource_group    = "vnet"

manager_image_id          = "{{ PACKER_CUSTOM_IMAGE_RESOURCE_ID }}"
worker_image_id          = "{{ PACKER_CUSTOM_IMAGE_RESOURCE_ID }}"
admin_username           = "localadmin"
admin_public_key_file    = "{{ PATH_TO_SSH_PRIVATE_KEY_FILE }}"

azure_ip_count          = 32
ucp_version             = "3.3.4"

permitted_source_addresses = [ "{{ SOURCE_IP_CIDR_TO_ACCESS_BASTION_HOST }}" ]

bastion_compute_sku    = "{{ BASTION_HOST_AZURE_VM_COMPUTE_SIZE }}"
worker_compute_sku     = "{{ WORKER_HOST_AZURE_VM_COMPUTE_SIZE }}"
manager_compute_sku    = "{{ MANAGER_HOST_AZURE_VM_COMPUTE_SIZE }}"
