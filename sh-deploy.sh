#!/bin/bash
set -x

. sh-env.sh

export ACR_SERVICE_PRINCIPAL_NAME="xxxx"
export ACR_SERVICE_PRINCIPAL_PASSWORD="yyyyy"
az ad sp list --display-name acrcallbinuvarghese-sp --query '[].appId' --output tsv

# Log Analytics Workspace
echo "Checking if the log analytics workspace ${CONTAINER_LOGANLTX_WKSP} exists.."
wsId=$(az monitor log-analytics workspace show \
   --resource-group $RESOURCE_GROUP \
   --workspace-name $CONTAINER_LOGANLTX_WKSP \
   --query id -o tsv)
if [ -n "$wsId" ]; then
    echo "Log Analytics Workspace:'${CONTAINER_LOGANLTX_WKSP}' exists . ID '${wsId}'"
else
    echo "Log Analytics Workspace:'${CONTAINER_LOGANLTX_WKSP}' does not exist in Resource Group '${RESOURCE_GROUP}'. Creating new..."
    wsId=$(az monitor log-analytics workspace create \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --workspace-name $CONTAINER_LOGANLTX_WKSP \
        --query id -o tsv)
    if [ -n "$wsId" ]; then
        echo "Log Analytics Workspace:'${CONTAINER_LOGANLTX_WKSP}' created . ID '${wsId}'"
    else
        echo "Log Analytics Workspace:'${CONTAINER_LOGANLTX_WKSP}' create failed Resource Group '${RESOURCE_GROUP}'."
        exit -1
    fi
fi
echo "Verifying the key of the log analytics workspace ${CONTAINER_LOGANLTX_WKSP}."
wsKey=$(az monitor log-analytics workspace get-shared-keys \
    --resource-group $RESOURCE_GROUP \
    --workspace-name $CONTAINER_LOGANLTX_WKSP \
    --query primarySharedKey -o tsv)
if [ -n "$wsId" ]; then
    echo "Log Analytics Workspace:'${CONTAINER_LOGANLTX_WKSP}' exists . Key:'${wsKey}'"
else
    echo "Log Analytics Workspace:'${CONTAINER_LOGANLTX_WKSP}' could not get workspace key. Resource Group '${RESOURCE_GROUP}'."
    exit -1
fi

# App Insights
echo "Checking for App Insights by name ${CONTAINER_APP_INSIGHTS} exists..."
aiId=$(az monitor app-insights component show  \
    --app $CONTAINER_APP_INSIGHTS \
    --resource-group $RESOURCE_GROUP \
    --query id -o tsv)
if [ -n "$aiId" ]; then
    echo "App Insights :'${CONTAINER_APP_INSIGHTS}' exists . ID '${aiId}'"
else
    echo "App Insights :'$CONTAINER_APP_INSIGHTS' does not exist in Resource Group '${RESOURCE_GROUP}'. Creating new..."
    aiId=$(az monitor app-insights component create \
        --app $CONTAINER_APP_INSIGHTS \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --query id -o tsv)
fi
echo "Verifying App Insights ${CONTAINER_APP_INSIGHTS} by getting instrumentation key.."
aiKey=$(az monitor app-insights component show \
    --resource-group $RESOURCE_GROUP \
    --app $CONTAINER_APP_INSIGHTS \
    --query instrumentationKey -o tsv)
if [ -n "$aiKey" ]; then
    echo "Got the key for App Insights :'${CONTAINER_APP_INSIGHTS}' . Key:'${aiKey}'"
else
    echo "App Insights:'${CONTAINER_APP_INSIGHTS}' could not get instrumentation key. Resource Group '$RESOURCE_GROUP'."
    exit -1
fi

echo "Getting connection string for App Insights:'${CONTAINER_APP_INSIGHTS}'"
aiConnectionString=$(az monitor app-insights component show \
    --app $CONTAINER_APP_INSIGHTS \
    --resource-group $RESOURCE_GROUP \
    --query connectionString \
    --output tsv)
if [ -n "$aiConnectionString" ]; then
    echo "Got the connection string for App Insights :'${CONTAINER_APP_INSIGHTS}' . ConnectionString:'${aiConnectionString}'"
else
    echo "App Insights:'${CONTAINER_APP_INSIGHTS}' could not get ConnectionString. Resource Group '$RESOURCE_GROUP'."
    exit -1
fi

echo "Checking whether Container App Env:${CONTAINER_ENV} exists.."
envId=$(az containerapp env show  \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_ENV \
    --query id \
    --output tsv)
if [ -n "$envId" ]; then
    echo "Container App Env :'${CONTAINER_ENV}' exists . CONTAINER_ENV_ID: '${envId}'"
else
    echo "Container App Env :'${CONTAINER_ENV}' does not exist in Resource Group '${RESOURCE_GROUP}'. Creating new..."

    envId=$(az containerapp env create --name $CONTAINER_ENV \
        --resource-group $RESOURCE_GROUP  \
        --location $LOCATION \
        --logs-destination azure-monitor \
        --logs-workspace-id $wsId \
        --logs-workspace-key $wsKey \
        --query id -o tsv)
    if [ -n "$envId" ]; then
        echo "Container App Environment created. Env:'${CONTAINER_ENV}' . Id:'${envId}'"
        
        echo "Setting the App Insights connectivity to App Environment Env:'${CONTAINER_ENV}' "
        az containerapp env telemetry app-insights set \
        --name $CONTAINER_ENV \
        --resource-group $RESOURCE_GROUP  \
        --connection-string ${aiConnectionString} \
        --enable-open-telemetry-traces true \
        --enable-open-telemetry-logs true
        if [ $? -eq 0 ]; then
            echo "Container App Env '$CONTAINER_ENV' connected to App Insights"
        else
            echo "Container App Env '$CONTAINER_ENV' could not be connected to App Insights"
            exit -1
        fi
    else
        echo "Container App Environment creation failed. Env:'${CONTAINER_ENV}'. Could not get Container App Env Id. Resource Group '${RESOURCE_GROUP}'."
        exit -1
    fi    
fi

echo "Checking for Container App:${CONTAINER_NAME} exists..."
appId=$(az containerapp show  \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query id \
    --output tsv)
if [ -n "$appId" ]; then
    echo "Container App :'$CONTAINER_NAME' exists . CONTAINER_ENV: '$envName'"
else
    echo "Container App Env :'$CONTAINER_NAME' does not exist in Resource Group '$RESOURCE_GROUP'. Creating new..."
    appId=$(az containerapp up --name $CONTAINER_NAME \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --environment $CONTAINER_ENV \
        --image $IMAGE_ACR \
        --target-port $CONTAINER_PORT \
        --ingress external \
        --query properties.configuration.ingress.fqdn \
        --registry-username $ACR_SERVICE_PRINCIPAL_NAME \
        --registry-password $ACR_SERVICE_PRINCIPAL_PASSWORD \
        --query id)
    if [ -n "$appId" ]; then
        echo "Container App created. App:'${CONTAINER_NAME}' . Id:'${appId}'"
    else
        echo "Container App creation failed. App:'${CONTAINER_NAME}'. Could not get Container App Id. Resource Group '${RESOURCE_GROUP}'."
        exit -1
    fi    
    echo "Checking the Container post creation. ${CONTAINER_NAME}; resource group:${RESOURCE_GROUP}"
    appId=$(az containerapp show  \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query id \
    --output tsv)
    if [ -n "$appId" ]; then
        echo "Container App Creation Verified. App:'${CONTAINER_NAME}' . Id:'${appId}'"
    else
        echo "Container App creation verification failed. App:'${CONTAINER_NAME}'. Could not get Container App Id. Resource Group '${RESOURCE_GROUP}'."
        exit -1
    fi    
    echo "Changing identity of container '${CONTAINER_NAME}' to '${IDENTITY_NAME}'"
    az containerapp identity assign --resource-group $RESOURCE_GROUP --name  $CONTAINER_NAME --user-assigned $IDENTITY_NAME
    if [ $? -eq 0 ]; then
        echo "Assigned identity to container '${CONTAINER_NAME}'; Identity ${IDENTITY_NAME}."
    else
        echo "Error assigning identity to container '${CONTAINER_NAME}'; Identity ${IDENTITY_NAME}."
    fi
    echo "Showing the identity of container '${CONTAINER_NAME}'; Resource Group ${RESOURCE_GROUP}."
    az containerapp identity show --name $CONTAINER_NAME --resource-group $RESOURCE_GROUP
fi

echo "Listing containers by name '${CONTAINER_NAME}'"
az container show  \
    --resource-group $RESOURCE_GROUP \
    --name  $CONTAINER_NAME \
    --query "containers[*].{Name: name, State: instanceView.currentState.state}"


echo "Deployment complete"
