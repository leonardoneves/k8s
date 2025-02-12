
### Setting Up Kubernetes with k3d, Cilium, and Essential Tools

#### 1\. Update and Upgrade Ubuntu

Before installing any tools, ensure your system is up-to-date:

```console
sudo apt update && sudo apt upgrade -y
```

* * * * *

#### 2\. Install Required Dependencies

Install basic dependencies like `curl`, `wget`, and `git`:

```console
sudo apt install -y curl wget git
```

* * * * *

#### 3\. Install Docker

k3d runs Kubernetes clusters inside Docker containers, so you need to install Docker first.

1.  Install Docker:

```console
sudo apt install -y docker.io
```

2.  Start and Enable Docker:

```console
sudo systemctl start docker
sudo systemctl enable docker
```

3.  Add Your User to the Docker Group (Optional but Recommended):

This allows you to run Docker commands without `sudo`.

```console
sudo usermod -aG docker $USER
newgrp docker
```

4.  Verify Docker Installation:

```console
docker --version
```

* * * * *

#### 4\. Install kubectl

kubectl is the Kubernetes command-line tool used to interact with your cluster.

1.  Download and Install kubectl:

```console
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

2.  Verify kubectl Installation:


```console
kubectl version --client
```

* * * * *

#### 5\. Install k3d

k3d is a lightweight wrapper around k3s that allows you to create Kubernetes clusters in Docker.

1.  Download and Install k3d:

```console
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

2.  Verify k3d Installation:

```console
k3d --version
```

* * * * *

#### 6\. Install k9s

k9s is a terminal-based UI for managing Kubernetes clusters.

1.  Download and Install k9s:

```console
curl -sS https://webinstall.dev/k9s | bash
```

2.  Add k9s to Your PATH (if not already added):

```console
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

3.  Verify k9s Installation:

```console
k9s version
```

* * * * *

#### 7\. Install kubectx and kubens

kubectx and kubens are tools for switching between Kubernetes contexts and namespaces.

1.  Install kubectx and kubens:


```console
sudo apt-get install kubectx
```

2.  Verify Installation:

```console
kubectx
kubens
```

* * * * *

#### 8\. Load Necessary Kernel Modules

To ensure proper networking functionality for Kubernetes and Cilium, load the required kernel modules (`overlay` and `br_netfilter`).

1.  Load the Modules Manually:

```console
sudo modprobe overlay
sudo modprobe br_netfilter
```

2.  Verify the Modules Are Loaded:

```console
lsmod | grep overlay
lsmod | grep br_netfilter
```

3.  Ensure Modules Are Loaded Automatically on Boot:

Create a configuration file to load the modules at boot:

```console
sudo vi /etc/modules-load.d/kubernetes.conf
```

Add the following lines:

```console
overlay
br_netfilter
```

Save and close the file.

4.  Reload Module Configurations:

```console
sudo systemctl restart systemd-modules-load.service
```

* * * * *

#### 9\. Configure Sysctl Settings

Configure `sysctl` settings to enable IP forwarding and bridge traffic filtering.

1.  Create a Sysctl Configuration File:

```console
sudo vi /etc/sysctl.d/99-kubernetes-cri.conf
```

2.  Add the Following Lines:

```console
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
```

3.  Apply the Settings:

```console
sudo sysctl --system
```

4.  Verify the Settings:

```console
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-ip6tables
```

* * * * *

#### 10\. Create a k3d Cluster Without Flannel

Now that everything is set up, create a k3d cluster without Flannel .

1.  Create the Cluster (3 masters and 3 worker nodes):

```console
k3d cluster create my-cluster --k3s-arg "--flannel-backend=none@server:*" -a 3 -s 3
```

2.  Verify the Cluster:

```console
kubectl get nodes
```

Nodes will be on NotReady state due to lack of CNI

* * * * *

#### 11\. Install Cilium

Replace Flannel with Cilium as the CNI.

1.  Install the Cilium CLI:

```console
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
tar xzvf cilium-linux-amd64.tar.gz
sudo mv cilium /usr/local/bin/
```

2.  Install Cilium:

```console
cilium install
```

3.  Verify Cilium Installation:

```console
cilium status
```

* * * * *

#### 12\. Test Network Policies

To ensure Cilium is working correctly, test a simple Network Policy.

1.  Create a Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  labels:
    app: test
spec:
  containers:
  - name: nginx
    image: nginx
```

Apply the Pod:

```console
kubectl apply -f test-pod.yaml
```

2.  Apply a Network Policy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-only-nginx
spec:
  podSelector:
    matchLabels:
      app: test
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 80
```

Apply the Network Policy:

```console
kubectl apply -f network-policy.yaml
```

#### Step 3: Deploy a Pod That Should Be Allowed

Create a Pod labeled with `role: frontend` to simulate an allowed client.
```console
kubectl run curlpod-allowed --image=curlimages/curl --labels="role=frontend" -- sleep infinity
```

Verify that this Pod can access the `test-pod`:

```console
kubectl exec curlpod-allowed -- curl -m 5 http://test-pod
```

If the Network Policy is working correctly, you should see the default NGINX welcome page in the output.

#### Step 4: Deploy a Pod That Should Be Denied

Create another Pod without the `role: frontend` label to simulate a denied client.

```console
kubectl run curlpod-denied --image=curlimages/curl -- sleep infinity
```

Attempt to access the `test-pod` from this Pod:

```console
kubectl exec curlpod-denied -- curl -m 5 http://test-pod
```

If the Network Policy is enforced correctly, this command should fail with a timeout error (e.g., `curl: (28) Operation timed out`), indicating that the request was blocked.

3.  Test the Policy:

Deploy another Pod and try to access the first Pod to verify that the Network Policy is enforced.
