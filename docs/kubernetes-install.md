

# Kubernetes Installation

This guide will install Kubernetes in a single node configuration, using Flannel for the CNI, and assumes that a recent version of Ubuntu is being used as the host OS. Full instructions for a more complicated configuration are available in [the official Kubernetes documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/).

## Container Runtime

This guide defaults to using Docker as the container runtime.

### Add Docker APT repository

``` bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Install packages

``` bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

### Validate installation

This command downloads a test image and runs it in a container. When the container runs, it should print an informational message and exit.

``` bash
sudo docker run hello-world
```

### Configure Docker daemon

The recommended configuration of the Docker daemon is provided by the Kubernetes team - particularly to use systemd for the management of the container’s cgroups:

``` bash
sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
```

### Restart Docker and enable on boot

``` bash
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## Disable Swap

Kubernetes refuses to run if swap is enabled on the node, so we disable swap immediately and then also disable it following a reboot:

``` bash
sudo swapoff -a
sudo sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab
```

## Install Kubeadm


### Add Kubernetes APT repository

``` bash
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

### Install packages

Accelleran dRAX currently supports Kubernetes up to version 1.20. The following command installs specifically this version:

``` bash
sudo apt-get update
sudo apt-get install -y kubelet=1.20.0-00 kubeadm=1.20.0-00 kubectl=1.20.0-00
sudo apt-mark hold kubelet kubeadm kubectl
```

## Configure Kubernetes


### Determine Node IP address

To initialize the Kubernetes cluster, the IP address of the node needs to be fixed, i.e. if this IP changes, a full reinstallation of Kubernetes will be required. This is generally the (primary) IP address of the network interface associated with the default gateway.

This IP could either be statically configured, or provided by a fixed DHCP lease - how exactly this is achieved is outside the scope of this document. From here on, this IP is referred to as `NODE_IP` - we store it as an environment variable for later use:

``` bash
export NODE_IP=a.b.c.d   # replace with the correct IP
```

### Determine Pod subnet

This guide assumes we will use Flannel as the CNI-based Pod network for this Kubernetes instance, which uses the 10.244.0.0/16 subnet by default. If you wish to use a different subnet, change it in the following command where we store it again as an environment variable for later use:

``` bash
export POD_NETWORK=10.244.0.0/16
```

### Initialize cluster

The following command initializes the cluster on this node:

``` bash
sudo kubeadm init --pod-network-cidr=$POD_NETWORK --apiserver-advertise-address=$NODE_IP
```

If this succeeds, we should see information for joining other worker nodes to this cluster. We won’t do that at this point, but it’s an indication that the command completed successfully.

### Prepare sudo-less access

To make kubectl work for our non-root user, run the following commands:

``` bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Install Flannel


### Prepare Manifest file

``` bash
curl -sSOJ https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sed -i '/net-conf.json/,/}/{ s#10.244.0.0/16#'"$POD_NETWORK"'#; }' kube-flannel.yml
```

### Apply Manifest file

``` bash
kubectl apply -f kube-flannel.yml
```

## Enable Pod Scheduling

By default, Kubernetes will not schedule Pods on the control-plane node for security reasons. As we’re running with a single Node, we need to remove the node-role.kubernetes.io/master taint, meaning that the scheduler will then be able to schedule Pods on it.

``` bash
kubectl taint nodes --all node-role.kubernetes.io/master-
```

