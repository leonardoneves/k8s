# Add Cilium Helm repo (if not already added)
helm repo add cilium https://helm.cilium.io/
helm repo update

# Install Cilium with your cluster-specific settings
helm install cilium cilium/cilium --namespace kube-system \
  --set devices='{virbr0,enp1s0}' \
  --set routingMode=native \
  --set ipv4NativeRoutingCIDR=10.244.0.0/16 \
  --set autoDirectNodeRoutes=true \
  --set kubeProxyReplacement=false \
  --set loadBalancer.interface=wlp2s0 \
  --set k8sServiceHost=10.0.0.23 \
  --set k8sServicePort=6443
