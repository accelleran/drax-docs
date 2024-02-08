# **Prepare the Kubernetes Cluster**

Below steps would prepare the cluster in the CU/RIC Virtual machine to be used for the rest of the deployment.

> PS: From the [Example Network Diagram](/drax-docs/) the VM IP is 10.55.5.3.

> All below steps would be implemented on the RIC/CU/CW VM.

## 1. Edit containerd Config

- Edit `/etc/containerd/config.toml`
```bash
version = 2
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.k8s.io/pause:3.9"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
    runtime_type = "io.containerd.runc.v2"
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
      SystemdCgroup = true
```
- Apply changes
```bash
sudo systemctl restart containerd.service
```

## 2. Install Kubernetes

- Disable swap and install kubernetes

```bash
sudo swapoff -a
sudo sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab

sudo apt-get install -y apt-transport-https ca-certificates curl
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt install -y kubelet kubeadm kubectl
```
- Initialize the cluster (using `10.55.5.3`)
```bash
export NODE_IP=10.55.5.3
export POD_NETWORK=10.244.0.0/16
sudo kubeadm init --pod-network-cidr=$POD_NETWORK --apiserver-advertise-address=$NODE_IP
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
curl -sSOJ https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sed -i '/net-conf.json/,/}/{ s#10.244.0.0/16#'"$POD_NETWORK"'#; }' kube-flannel.yml
kubectl apply -f kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## 3. Install Helm

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

## 4. Deploy longhorn

- longhorn would be used for storage managment
```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install --create-namespace --namespace=longhorn-system longhorn longhorn/longhorn
```
- Make sure all pods are operating normaly.
```bash
watch kubectl get pods -A
```

> ***Missing manual steps to create the disk***

## 5. Deploy a Load Balancer
> PS: From the [Example Network Diagram](/drax-docs/) the K8s Cluster IP pool is `10.55.5.30-10.55.5.39`


- Using purelb as a load balancer to the cluster.
> ***To be changed with metallb***
```bash
helm repo add purelb https://gitlab.com/api/v4/projects/20400619/packages/helm/stable
helm repo update
helm install --create-namespace --namespace=purelb purelb purelb/purelb
```
- Add the allowed IP range to be used in the cluster.
```bash
tee purelb-ip_pool.yaml <<EOF
apiVersion: purelb.io/v1
kind: ServiceGroup
metadata:
  name: default
  namespace: purelb
spec:
  local:
    v4pools:
    - subnet: 10.55.5.0/24
      pool: 10.55.5.30-10.55.5.39
      aggregation: default
EOF
kubectl apply -f purelb-ip_pool.yaml -n purelb
```
```bash
watch kubectl get pods -A
```

> # Next Step [DRAX Installation](/drax-docs/drax_ng-install/)