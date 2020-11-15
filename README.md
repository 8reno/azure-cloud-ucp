This repository contains the code necessary to provision an Docker Enterprise cluster on Azure public cloud in order to troubleshoot a number of issues with Docker Enterprise.

The architecture of this infrastructure is:

- Azure vnet with 10.0.0.0/22 address space
- Public subnet (10.0.1.0/24) with an Ubuntu 18.04 Marketplace Image acting as a bastion host
- Docker subnet (10.0.2.0/23) containing two VM scale sets (manager and worker) from Custom VM Images.
- An internal Azure load balancer is provisioned, statically assigned to the IP address of 10.0.3.254, to handle requests to the manager scale set instance, in particular the UCP portal.
- The VMSS Custom VM Images are built via Packer. They are based on RHEL7 Azure marketplace images and simply provision the Docker Enterprise yum repositories and Docker Enterprise Engine.
- A small cluster is provisioned (1 manager and 3 worker nodes). VMSS Scaling is set to Manual as no scaling action is required for these purposes.
- cloud-init is used to deploy the Azure Cloud provider configuration file and the UCP Config TOML file to the nodes.
- A k8s workload (nginx) will be deployed with an External Load Balancer k8s service configuration.  The IP address of this LB will be statically assigned to 10.0.3.253.

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

6.1.3 internal IP address of the manager VMSS instance (MANAGER000000_INTERNAL_IP) and the worker VMSS instances (WORKER00000N_INTERNAL_IP).  N should range from 0 to 2.

7. Manually provision docker enterprise cluster as follows:

7.1 ssh into manager000000 VMSS instance via bastion host and install Swarm and Docker Enterprise

```
ssh -i PATH_TO_PRIVATE_KEY_FILE localadmin@BASTION_PUBLIC_IP_ADDRESS; exit # for some reason directly tunnelling to docker nodes fails unless this is done first
ssh -i PATH_TO_PRIVATE_KEY_FILE -J localadmin@BASTION_PUBLIC_IP_ADDRESS localadmin@MANAGER000000_INTERNAL_IP
sudo su
docker swarm init # initialise swarm cluster. take record of worker join token output for later use (WORKER_JOIN_TOKEN)
docker config create com.docker.ucp.config /tmp/ucp-config.toml # create docker config object from cloud-init supplied file
read -s UCP_PASSWORD # enter ucp admin password
docker container run --name ucp-init --volume /var/run/docker.sock:/var/run/docker.sock docker/ucp:3.3.4 install --admin-username admin --admin-password $UCP_PASSWORD --san 10.0.3.254 --san localhost --external-service-lb 10.0.3.254 --pod-cidr 10.0.2.0/23 --existing-config # install UCP
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

7.4 deploy k8s workload with ExternalLB type LoadBalancer from bastion host

7.4.1 set up kubectl on bastion host

```
ssh -i PATH_TO_PRIVATE_KEY_FILE localadmin@BASTION_PUBLIC_IP_ADDRESS
read -s UCP_PASSWORD
AUTHTOKEN=$(curl -sk -d "{\"username\":\"admin\",\"password\":\"$UCP_PASSWORD\"}" https://10.0.3.254/auth/login | jq -r .auth_token)
curl -k -H "Authorization: Bearer $AUTHTOKEN" https://10.0.3.254/api/clientbundle -o bundle.zip
unzip bundle.zip 
eval "$(<env.sh)"
curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.14.0/bin/linux/amd64/kubectl"
chmod +x kubectl
```

7.4.2 deploy nginx helm chart 
```
export LOADBALANCER_IP="10.0.3.253"
curl -LO "https://get.helm.sh/helm-v3.3.1-linux-amd64.tar.gz"
tar zxvf helm-v3.3.1-linux-amd64.tar.gz
linux-amd64/helm repo add bitnami https://charts.bitnami.com/bitnami
cat <<EOF > nginx.yaml
---
service:
  loadBalancerIP: $LOADBALANCER_IP
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
EOF
linux-amd64/helm install nginx bitnami/nginx -f nginx.yaml
./kubectl get svc -A
```

7.5 In the Azure Portal, observe an Azure Load Balancer being created automatically by the Azure cloud provider (called "kubernetes-internal" or "worker-internal").  

Select this Load Balancer and in the Backend Pools tab, observe the warning:

"Backend pool 'kubernetes' was removed from Virtual machine scale set 'worker'. Upgrade all the instances of 'worker' for this change to apply

Notice that the 3 worker instances are in the "kubernetes" Backend Pool.

7.6 In the Azure Portal, select the "worker" Virtual Machine Scale Set resource, and select Instances.  You will now observe that all the worker instances state that they do not conform to the Latest Model.

7.7 Update the VMSS instances to the Latest VMSS model:

In the Instances tab, select all three worker instances and click Upgrade.

Once the upgrade is complete, click Refresh and the instances will now show that they are updated to the Latest Model.

However, in the kubernetes-internal Load Balancer resource, click on Backend Pools.  The warning is now no longer displayed, however you will see that three workers are no longer in the "kubernetes" backend pool.

This is the description of the bug that was reported upstream.  The cloud provider only updates the load balancer details in the backend instances and not the VMSS manifest.  When upgrading the instances to match the manifest, they are removed from the Load Balancer backend.

7.8 The expected behaviour from the bugfix is that when the helm chart with an external Load Balancer is deployed, the cloud provider will update both the backend instances as well as the VMSS manifest with the load balancer details. 

