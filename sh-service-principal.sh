#!/bin/bash
set -x
#export ACR_SERVICE_PRINCIPAL_PASSWORD="shy8xxxx-xxx-xxx-xAPdD"
#https://learn.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal

. sh-env.sh

export DELETE_IF_EXISTS="yes"

if [[ -z ${ACR_SERVICE_PRINCIPAL_NAME} ]] ; then
    echo "Service principal value is not specified"
    exit -1
fi
USER_NAME=$(az ad sp list --display-name $ACR_SERVICE_PRINCIPAL_NAME --query "[].appId" --output tsv)
if [[ -z ${USER_NAME} ]] ; then
    echo "ACR Service principal is not existing. So creating it for ACR ${ACR_NAME}"
    # Obtain the full registry ID
    ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query "id" --output tsv)

    if [[ -z ${ACR_REGISTRY_ID} ]] ; then
        echo "ACR Registry ID could not be found for ${ACR_NAME}"
    else
        echo "Got RegistryID; ACR for ACR:${ACR_NAME}; Registry ID:${ACR_REGISTRY_ID}"
        PASSWORD=$(az ad sp create-for-rbac --name $ACR_SERVICE_PRINCIPAL_NAME --scopes $ACR_REGISTRY_ID --role acrpull --query "password" --output tsv)
        USER_NAME=$(az ad sp list --display-name $ACR_SERVICE_PRINCIPAL_NAME --query "[].appId" --output tsv)
    fi

    if [[ -z ${USER_NAME} ]] && [[ -z ${PASSWORD} ]]  ; then
        echo "Got credentials for SP Name:${ACR_SERVICE_PRINCIPAL_NAME}; UserName:${USER_NAME}"
    fi
else
    echo "Service Principal Exists for SP Name:${ACR_SERVICE_PRINCIPAL_NAME}; UserName:${USER_NAME}"
    if [[ "yes" == "${DELETE_IF_EXISTS}" ]] ; then 
        echo "Deleting the service principal SP Name:${ACR_SERVICE_PRINCIPAL_NAME}; UserName:${USER_NAME}"
        echo "Delete from Azure portal Entra ID UI"
    fi
fi

# Service Principal Can be seen in EntraID UI under App Rgistrations->All Applications-Name: (specified in env,sh )