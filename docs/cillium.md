
helm install cilium cilium/cilium --namespace kube-system --set ipam.mode=kubernetes --set devices='{virbr0}' --set kubeProxyReplacement=strict --set nodePort.enabled=true --set k8sServiceHost=10.0.0.23 --set k8sServicePort=6443 --set kubeProxyReplacement=false
