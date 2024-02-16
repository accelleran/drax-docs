# **Prepare the Kubernetes Cluster**

Below steps would prepare the cluster in the CU/RIC Virtual machine to be used for the rest of the deployment.

> PS: From the [Example Network Diagram](/drax-docs/) the VM IP is 10.55.5.3.

> All below steps would be implemented on the RIC/CU/CW VM.

## 1. Install and Edit containerd Config

- Install containerd
```bash
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install containerd.io
```

- Edit containerd config and restart it:
```bash
sudo rm -rf /etc/containerd/config.toml
sudo tee /etc/containerd/config.toml <<EOF
version = 2
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.k8s.io/pause:3.9"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
    runtime_type = "io.containerd.runc.v2"
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
      SystemdCgroup = true
EOF
sudo systemctl restart containerd.service
```

## 2. Install Kubernetes

- Disable swap and prepare bridges 
```bash
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.arp_announce=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.arp_ignore=2" | sudo tee -a /etc/sysctl.conf
echo "fs.inotify.max_user_instances=4096" | sudo tee -a /etc/sysctl.conf
echo "br_netfilter" | sudo tee /etc/modules-load.d/kubernetes.conf
sudo modprobe br_netfilter
sudo sysctl --system

sudo swapoff -a
sudo sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab
```

- install kubernetes

```bash
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt install -y kubelet=1.29.1-1.1 kubeadm=1.29.1-1.1 kubectl=1.29.1-1.1
sudo apt-mark hold kubelet kubeadm kubectl
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

## 4. Prepare Storage

- Prepare local storage
```bash
curl https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml -o /tmp/local-path-storage.yaml

kubectl apply -f /tmp/local-path-storage.yaml
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF
```


## 5. Deploy a Load Balancer
> PS: From the [Example Network Diagram](/drax-docs/) the K8s Cluster IP pool is `10.55.5.30-10.55.5.39`


- Using purelb as a load balancer to the cluster.
> ***To be changed with metallb***
```bash
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install --create-namespace --namespace=metallb-system metallb metallb/metallb --version 0.13.12
```
- Add the allowed IP range to be used in the cluster.
```bash
tee metallb-pool.yaml <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: loadbalancer-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.55.5.30-10.55.5.39
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
EOF
kubectl apply -f metallb-pool.yaml
```
```bash
watch kubectl get pods -A
```

> # Next Step [DRAX Installation](/drax-docs/drax_ng-install/)