LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"
RG_NAME="php-laravel-redis-rg"
AKS_VERSION='1.28.3'
export CONTAINER_NAME="php-laravel"

az group create --location $LOCATION --name $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name aks-deployment \
    --template-file ./infra/main.bicep \
    --parameters ./infra/main.parameters.json \
    --parameters location=$LOCATION \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
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
kubectl logs myphp -f