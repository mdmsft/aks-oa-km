# Infrastructure
```sh
terraform init
terraform apply -var-file main.tfvars -auto-approve
```

# Container images
```sh
az acr import -n registry-name --source source-registry-name.azurecr.io/image-repository:image-tag -u source-registry-name -p source-registry-password
```

# Cluster login
```sh
az aks get-credentials -n cluster-name -g cluster-resource-group --public-fqdn --overwrite-existing
kubelogin convert-kubeconfig -l msi|azurecli
```

# NGINX ingress controller
```sh
helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.service.annotations."service\.beta\.kubernetes\.io\/azure-load-balancer-internal"="true" --set controller.service.loadBalancerIP=10.218.36.x
```