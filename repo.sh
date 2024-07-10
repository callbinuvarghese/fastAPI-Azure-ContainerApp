#!/bin/bash
export APP="fastapi1"
export IMAGE_VERSION="v1"
export IMAGE="binu/${APP}:${IMAGE_VERSION}"
export ACR_NAME="acrcallbinuvarghese"
mycontainers=$(az acr repository list --name $ACR_NAME --output tsv)
for i in $mycontainers
do
    echo -n "$REGISTRY.azurecr.io/$i:"
    az acr repository show-tags -n $ACR_NAME --repository $i --output tsv|tail -1
done
