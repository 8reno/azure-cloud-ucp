#cloud-config

write_files:
  - path: /etc/kubernetes/azure.json
    permissions: 0644
    content: |
      {
        "cloud":"AzurePublicCloud",
        "tenantId": "${tenant_id}",
        "subscriptionId": "${subscription_id}",
        "aadClientId": "${aad_client_id}",
        "aadClientSecret": "${aad_client_secret}",
        "resourceGroup": "${docker_resource_group}",
        "location": "${vnet_region}",
        "subnetName": "/${docker_subnet_name}",
        "securityGroupName": "${security_group_name}",
        "vnetName": "${vnet_name}",
        "vnetResourceGroup": "${vnet_resourcegroup_name}",
        "vmType": "vmss",
        "primaryScaleSetName": "${docker_worker_scaleset_name}",
        "loadBalancerName": "${k8s_lb_name}",
        "loadBalancerSku": "${k8s_lb_sku}",
        "cloudProviderBackoff": false,
        "cloudProviderBackoffRetries": 0,
        "cloudProviderBackoffExponent": 0,
        "cloudProviderBackoffDuration": 0,
        "cloudProviderBackoffJitter": 0,
        "cloudProviderRatelimit": false,
        "cloudProviderRateLimitQPS": 0,
        "cloudProviderRateLimitBucket": 0,
        "useManagedIdentityExtension": false,
        "useInstanceMetadata": true
      }
  - path: /tmp/ucp-config.toml
    permissions: 0600
    content: |
      [scheduling_configuration]
        enable_admin_ucp_scheduling = true
        default_node_orchestrator = "kubernetes"
      [audit_log_configuration]
        level = "request"
      [log_configuration]
        level = "INFO"
      [license_configuration]
        auto_refresh = false
      [cluster_config]
        cloud_provider = "azure"
        nodeport_range = "32768-35535"
        azure_ip_count = "0"
        custom_kube_api_server_flags = ["--profiling=false"]
        custom_kube_scheduler_flags = ["--profiling=false"]
        custom_kube_controller_manager_flags = ["--profiling=false", "--terminated-pod-gc-threshold=10"]
        pre_logon_message = ""
