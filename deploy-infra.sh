LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
RG_NAME="php-laravel-redis-rg"
AKS_VERSION='1.28.3'
export CONTAINER_NAME="php-laravel"
AKS_ADMIN_GROUP_NAME='aks-admin-group'
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)

AKS_ADMIN_GROUP_OBJECT_ID=$(az ad group create --display-name $AKS_ADMIN_GROUP_NAME --mail-nickname $AKS_ADMIN_GROUP_NAME --query id -o tsv)
az ad group member add --group $AKS_ADMIN_GROUP_NAME --member-id $CURRENT_USER_ID

az deployment group create \
    --resource-group $RG_NAME \
    --name aks-deployment \
    --template-file ./infra/main.bicep \
    --parameters ./infra/main.parameters.json \
    --parameters location=$LOCATION \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters adminGroupObjectID=$AKS_ADMIN_GROUP_OBJECT_ID \
    --parameters aksVersion=$AKS_VERSION \
    --parameters dnsPrefix='aks-basic'

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
export ACR_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.acrName.value' -o tsv)
export REDIS_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.redisName.value' -o tsv)
export REDIS_PASSWORD=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.redisPassword.value' -o tsv)

az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin --context 'php-laravel-redis' --admin --overwrite-existing

docker build -t  "$ACR_NAME.azurecr.io/$CONTAINER_NAME:latest" .
az acr login --name $ACR_NAME
docker push "$ACR_NAME.azurecr.io/$CONTAINER_NAME:latest"

envsubst < ./manifests/php.yaml | kubectl apply -f -
kubectl wait --for=condition=Ready pod/myphp
kubectl logs myphp -f
