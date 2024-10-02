#!/bin/bash
AZURE_SUBSCRIPTION_ID="${1}"
# Enable the Crossplane Helm Chart repository
helm repo add \
crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Run the Helm dry-run to see all the Crossplane components Helm installs
helm install crossplane \
crossplane-stable/crossplane \
--dry-run --debug \
--namespace crossplane-system \
--create-namespace

# Install the Crossplane components using helm install
helm install crossplane \
crossplane-stable/crossplane \
--namespace crossplane-system \
--create-namespace

# Verify Crossplane installed with kubectl get pods
kubectl get pods -n crossplane-system

# Verify Crossplane installed with kubectl get pods
kubectl api-resources  | grep crossplane

# Install Azure Provider for Crossplane
kubectl apply -f ./providers/azure-provider.yaml

# Get the install providers
kubectl get providers

# Login to Azure using the Azure CLI
az login
az account set --subscription ${AZURE_SUBSCRIPTION_ID}

# Create an Azure Service Principal for Crossplane
az ad sp create-for-rbac \
--sdk-auth \
--role Owner \
--scopes /subscriptions/${AZURE_SUBSCRIPTION_ID} \
--output json > ./azure-creds.json

# Create a Kubernetes Secret from the Azure Service Principal
kubectl create secret \
generic azure-secret \
-n crossplane-system \
--from-file=creds=./azure-creds.json

# Check the secret was created
kubectl describe secret azure-secret -n crossplane-system

# Apply the ProviderConfig with the command
kubectl apply -f ./providerConfigs/azure-provider-config.yaml

# Create a managed resource class for Azure Virtual Machines
kubectl create -f ./managedResourceClasses/virtual-network.yaml

# Verify the managed resource class was created
kubectl get virtualnetwork.network
