these are the AZ CLI commands to set up a Service Principal and a Storage Container for the TF state

substitute appropriate values 

```
az ad sp create-for-rbac --name="terraform" --role="Contributor" --scopes="/subscriptions/{{ SUBSCRIPTION_ID }}"
az group create --name {{ STATE_RESOURCE_GROUP_NAME }} --location {{ LOCATION }}
az storage account create --name {{ STATE_STORAGE_ACCOUNT_NAME }} --resource-group {{ STATE_RESOURCE_GROUP_NAME }}
az storage container create --name {{ STATE_STORAGE_CONTAINER_NAME }} --account-name {{ STATE_STORAGE_ACCOUNT_NAME }}
az storage account keys list --account-name {{ STATE_STORAGE_ACCOUNT_NAME }}
```

the last command should output the Access Key Name (STATE_STORAGE_ACCESS_KEY_NAME) and Key (STATE_STORAGE_ACCESS_KEY)
