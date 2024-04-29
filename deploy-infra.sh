SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
AUE_RG_NAME="php-laravel-redis-syd-rg"
AUSE_RG_NAME="php-laravel-redis-mel-rg"
AKS_VERSION='1.28.3'
export CONTAINER_NAME="php-laravel"
AKS_ADMIN_GROUP_NAME='aks-admin-group'
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)

AKS_ADMIN_GROUP_OBJECT_ID=$(az ad group create --display-name $AKS_ADMIN_GROUP_NAME --mail-nickname $AKS_ADMIN_GROUP_NAME --query id -o tsv)
az ad group member add --group $AKS_ADMIN_GROUP_NAME --member-id $CURRENT_USER_ID

# Sydney
az group create --name $AUE_RG_NAME --location 'australiaeast'

az deployment group create \
    --resource-group $AUE_RG_NAME \
    --name aks-deployment \
    --template-file ./infra/main.bicep \
    --parameters ./infra/main.parameters.json \
    --parameters location='australiaeast' \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters adminGroupObjectID=$AKS_ADMIN_GROUP_OBJECT_ID \
    --parameters aksVersion=$AKS_VERSION \
    --parameters dnsPrefix='aks-basic' \
    --parameters addressPrefix='10.1.0.0/16'

export AUE_CLUSTER_NAME=$(az deployment group show --resource-group $AUE_RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
export ACR_NAME=$(az deployment group show --resource-group $AUE_RG_NAME --name aks-deployment --query 'properties.outputs.acrName.value' -o tsv)

az aks get-credentials -g $AUE_RG_NAME -n $AUE_CLUSTER_NAME --admin --context 'php-laravel-redis-syd' --admin --overwrite-existing

docker build -t  "$ACR_NAME.azurecr.io/$CONTAINER_NAME:latest" .
az acr login --name $ACR_NAME
docker push "$ACR_NAME.azurecr.io/$CONTAINER_NAME:latest"

# Melbounre
az group create --name $AUSE_RG_NAME --location 'australiasoutheast'

az deployment group create \
    --resource-group $AUSE_RG_NAME \
    --name aks-deployment \
    --template-file ./infra/main.bicep \
    --parameters ./infra/main.parameters.json \
    --parameters location='australiasoutheast' \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters adminGroupObjectID=$AKS_ADMIN_GROUP_OBJECT_ID \
    --parameters aksVersion=$AKS_VERSION \
    --parameters dnsPrefix='aks-basic' \
    --parameters addressPrefix='10.2.0.0/16'

export REDIS_NAME=$(az deployment group show --resource-group $AUSE_RG_NAME --name aks-deployment --query 'properties.outputs.redisName.value' -o tsv)
export REDIS_PASSWORD=$(az deployment group show --resource-group $AUSE_RG_NAME --name aks-deployment --query 'properties.outputs.redisPassword.value' -o tsv)

az aks get-credentials -g $AUSE_RG_NAME -n $AUSE_CLUSTER_NAME --admin --context 'php-laravel-redis-mel' --admin --overwrite-existing

docker build -t  "$ACR_NAME.azurecr.io/$CONTAINER_NAME:latest" .
az acr login --name $ACR_NAME
docker push "$ACR_NAME.azurecr.io/$CONTAINER_NAME:latest"

# deploy PHP container to Sydney region AKS cluster, but use the Melbourne region Redis instance
envsubst < ./manifests/php.yaml | kubectl apply -f -
kubectl wait --for=condition=Ready pod/php
kubectl logs php -f
