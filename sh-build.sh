#!/bin/bash
set -x

. sh-env.sh

if [ $(az group exists --name $RESOURCE_GROUP) = false ]; then
    echo "Creating new Rescource Group. Resource Group not existing $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION
else
    echo "Resource Group existing $RESOURCE_GROUP"
fi
az group show --name $RESOURCE_GROUP

az acr show --name $ACR_NAME  --resource-group $RESOURCE_GROUP &>/dev/null
if [ $? -eq 0 ]; then
  echo "ACR '$ACR_NAME' already exists."
else
  echo "ACR '$ACR_NAME' does not exist. Creating..."
    az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Standard --location $LOCATION
fi
acrName=$(az acr list  --resource-group $RESOURCE_GROUP --name $ACR_NAME --output tsv)
echo "Checked the ACR $acrName"

#$(az acr login -n $ACR_NAME)
TOKEN=$(az acr login --name $ACR_NAME --expose-token --output tsv --query accessToken)
echo "ACR Login success TOKEN=$TOKEN"

# Check if the image exists by listing tags
#az acr repository show-tags --name acrcallbinuvarghese --repository binu/fastapi1  --output ts
tags=$(az acr repository show-tags --name $ACR_NAME --repository $IMAGE_PREFIX --output tsv)
if [ -n "$tags" ]; then
  echo "Image '$IMAGE_ACR' exists in ACR '$ACR_NAME'. tags '$tags'"
else
  echo "Image '$IMAGE_ACR' does not exist in ACR '$ACR_NAME'."
  az acr build --registry $ACR_NAME --image $IMAGE_ACR .
fi


#docker login "${ACR_NAME}.azurecr.io" --username 00000000-0000-0000-0000-000000000000 --password-stdin <<< $TOKEN
#echo "Docker login complete"

#docker tag $IMAGE "${ACR_NAME}.azurecr.io/${IMAGE}"
#az acr build --registry t --image my-sample-app .