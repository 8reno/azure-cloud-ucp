This repository contains the code necessary to provision an Docker Enterprise cluster on Azure public cloud in order to troubleshoot a number of issues with Docker Enterprise 3.1.

The architecture of this infrastructure is:

- Azure vnet with 10.0.0.0/22 address space
- Public subnet (10.0.1.0/24) with an Ubuntu 18.04 Marketplace Image acting as a bastion host
- Docker subnet (10.0.2.0/23) containing two VM scale sets (manager and worker) from Custom VM Images.
- An internal Azure load balancer is provisioned to handle requests to the manager scale set instances, in particular the UCP portal.
- The VMSS Custom VM Images are built via Packer. They are based on RHEL7 Azure marketplace images and simply provision the Docker Enterprise yum repositories and Docker Enterprise Engine.
- VMSS Scaling is set to Manual.  No scaling action is required for these purposes.
- cloud-init is used to deploy the Azure Cloud provider configuration file and the UCP Config TOML file to the nodes.

To provision cluster:

1. set up bootstrapping Azure resources (Service Prinicpal, Terraform state file and Custom Images resource group) via AZ CLI commands contained in the BOOTSTRAP.md file

2. Generate SSH public/private key pair for ssh access to all VM/VMSS instances.

3. Update Packer files with appropriate values:

3.1 Update the packer/buildvars.json file with appropriate values.

```
  "client_id"                             : "{{ SERVICE_PRINCIPAL_CLIENT_ID  }}",
  "client_secret"                         : "{{ SERVICE_PRINCIPAL_CLIENT_SECRET }}",
  "subscription_id"                       : "{{ AZURE_SUBSCRIPTION_ID }}",
  "tenant_id"                             : "{{ AZURE_TENANT_ID }}",
  "vm_size"                               : "{{ AZURE_VM_SIZE }}",
  "location"                              : "{{ AZURE_LOCATION }}",
  "ssh_private_key_file"                  : "{{ PATH_TO_SSH_PRIVATE_KEY }}"
```

3.2 Update the packer/scripts/deploy.sh file with appropriate values.

Substitute the "{{ DOCKER_EE_SUBSCRIPTION }}" reference in the deploy.sh with a valid Docker EE subscription ID.

4. Build Custom Image via packer

```
cd packer
packer build -force -var-file buildvars.json build.json
```

Make note of the Image resource identifier to add the terraform/01-variables.auto.tfvars

5. Update Terraform files with appropriate values:

5.1 Update terraform/01-variables.auto.tfvars file with appopriate values:

```
subscription_id   = "{{ AZURE_SUBSCRIPTION_ID }}"
tenant_id         = "{{ AZURE_TENANT_ID }}"
client_id         = "{{ AZURE_SERVICE_PRINCIPAL_CLIENT_ID }}"
client_secret     = "{{ AZURE_SERVICE_PRINCIPAL_CLIENT_SECRET }}""

location          = "{{ AZURE_LOCATION }}"

manager_image_id          = "{{ PACKER_CUSTOM_IMAGE_RESOURCE_ID }}"
worker_image_id          = "{{ PACKER_CUSTOM_IMAGE_RESOURCE_ID }}"
admin_public_key_file    = "{{ PATH_TO_SSH_PRIVATE_KEY_FILE }}"

permitted_source_addresses = [ "{{ SOURCE_IP_CIDR_TO_ACCESS_BASTION_HOST }}" ]

bastion_compute_sku    = "{{ BASTION_HOST_AZURE_VM_COMPUTE_SIZE }}"
worker_compute_sku     = "{{ WORKER_HOST_AZURE_VM_COMPUTE_SIZE }}"
manager_compute_sku    = "{{ MANAGER_HOST_AZURE_VM_COMPUTE_SIZE }}"
```

5.2 Update terraform/02-provider.tf with appropriate values (from the Azure bootstrapping in step 1 above)

```
storage_account_name = "{{ STATE_STORAGE_ACCOUNT_NAME }}"
container_name       = "{{ STATE_STORAGE_CONTAINER_NAME }}"
key                  = "{{ STATE_STORAGE_ACCESS_KEY_NAME }}"
access_key           = "{{ STATE_STORAGE_ACCESS_KEY }}"
```

6. Build azure resources with Terraform

```
cd terraform
terrform init
terraform validate
terraform plan
terraform apply -auto-approve
```

6.1 Take note of the following:
 
6.1.1 public IP address dynamically assigned to the bastion host (BASTION_PUBLIC_IP_ADDRESS)

6.1.2 internal IP address of the manager VMSS Azure Load Balancer (should be 10.0.3.254)

6.1.3 internal IP addresses of the manager VMSS instances (MANAGER00000N_INTERNAL_IP) and the worker VMSS instances (WORKER00000N_INTERNAL_IP).  N should range from 0 to 2.

7. Manually provision docker enterprise cluster as follows:

7.1 ssh into manager000000 VMSS instance via bastion host and install Swarm and Docker Enterprise

```
ssh -i PATH_TO_PRIVATE_KEY_FILE localadmin@BASTION_PUBLIC_IP_ADDRESS; exit # for some reason directly tunnelling to docker nodes fails unless this is done first
ssh -i PATH_TO_PRIVATE_KEY_FILE -J localadmin@BASTION_PUBLIC_IP_ADDRESS localadmin@MANAGER000000_INTERNAL_IP
sudo su
docker swarm init # initialise swarm cluster. take record of worker join token output for later use (WORKER_JOIN_TOKEN)
docker config create com.docker.ucp.config /tmp/ucp-config.toml # create docker config object from cloud-init supplied file
read -s UCP_PASSWORD # enter ucp admin password
docker container run --name ucp-init --volume /var/run/docker.sock:/var/run/docker.sock docker/ucp:3.3.1 install --admin-username admin --admin-password $UCP_PASSWORD --san 10.0.3.254 --san localhost --external-service-lb 10.0.3.254 --pod-cidr 10.0.2.0/23 --existing-config # install UCP
docker swarm join-token manager # take record of manager join token output for later use (MANAGER_JOIN_TOKEN)
```

7.2 ssh into the 3 worker00000n VMs via bastion host and join workers to Swarm cluster

```
ssh -i PATH_TO_PRIVATE_KEY_FILE -j localadmin@BASTION_PUBLIC_IP_ADDRESS localadmin@WORKER00000N_INTERNAL_IP
sudo docker swarm join --token WORKER_JOIN_TOKEN MANAGER000000_INTERNAL_IP:2377
```

7.3 check Docker UCP portal to ensure Docker cluster is healthy

```
ssh -i PATH_TO_SSH_PRIVATE_KEY -L 8443:10.0.3.254:443 localadmin@BASTION_PUBLIC_IP_ADDRESS  # set up ssh port forwarding to internal UCP portal address
```
browse to https://localhost:8443

7.4 ssh into manager00000001 VM via bastion host and join manager to Swarm cluster

```
sudo docker swarm join --token MANAGER_JOIN_TOKEN MANAGER000000_INTERNAL_IP:2377
```

7.5 observe logs of ucp-kv docker containers on both manager0000000 and manager000001 nodes


