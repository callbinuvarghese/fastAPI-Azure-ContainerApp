#!/bin/bash
set -x

export APP="fastapi1"
export IMAGE_VERSION="v1"
export IMAGE_PREFIX="binu/${APP}"
export IMAGE="binu/${APP}:${IMAGE_VERSION}"
export ACR_NAME="acrcallbinuvarghese"
export IMAGE_ACR="${ACR_NAME}.azurecr.io/${IMAGE}"
export RESOURCE_GROUP="${APP}-contapps-rg"
export LOCATION="eastus2"
export GITHUB_USERNAME="callbinuvarghese"
export CONTAINER_NAME="${APP}-cont-app"
export CONTAINER_ENV="${APP}-cont-env"
export CONTAINER_LOGANLTX_WKSP="${APP}-loganltx-wksp"
export CONTAINER_APP_INSIGHTS="${APP}-app-ins8s"
export IDENTITY_NAME="${APP}-identity"
export ACR_SERVICE_PRINCIPAL_NAME="${ACR_NAME}-sp"
export CONTAINER_PORT=50505
#printenv
