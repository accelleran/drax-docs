# Kubernetes Installation (v1.24)

This chapter will install Kubernetes, using Flannel for the CNI.
This guide defaults to using Containerd as the container runtime.
For more information on installing Kubernetes, see the [official Kubernetes documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/).


## Disable Swap

Kubernetes refuses to run if swap is enabled on the node, so we disable swap immediately and then also disable it following a reboot:

``` bash
sudo swapoff -a
sudo sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab
```

## Install Kubernetes and suplemental libraries 

Add the Kubernetes APT repository:

``` bash
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
```

Accelleran dRAX currently supports Kubernetes up to version 1.24. The following command installs specifically this (1.24) version of k8s together with containerd end suplemental libraries:

``` bash
sudo apt-get install -y runc libc6 containerd kubelet=1.24.0-00 kubeadm=1.24.0-00 kubectl=1.24.0-00
sudo apt-mark hold kubelet kubeadm kubectl
```

## Configure Containerd

``` bash
sudo rm -rf /etc/containerd/config.toml
sudo systemctl restart containerd.service
sudo systemctl enable containerd.service
sudo sysctl -p
```


## Letting IPTables See Bridged Traffic and IP Forwarding Enabling 

In order k8s nodes can see bringed traffic properly, iptables should be configured to allow bringed traffic together with enabled ip-forwarding.  

``` bash
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf
sudo modprobe br_netfilter
```

## Configure Kubernetes

To initialize the Kubernetes cluster, the IP address of the node needs to be fixed, i.e. if this IP changes, a full re-installation of Kubernetes will be required.
This is generally the (primary) IP address of the network interface associated with the default gateway.
From here on, this IP is referred to as `$NODE_IP` - we store it as an environment variable for later use:

``` bash
export NODE_IP=1.2.3.4   # replace 1.2.3.4 with the correct IP
```

This guide assumes we will use Flannel as the CNI-based Pod network for this Kubernetes instance, which uses the `10.244.0.0/16` subnet by default.
We store it again as an environment variable for later use, and of course if you wish to use a different subnet, change the command accordingly:

``` bash
export POD_NETWORK=10.244.0.0/16
```

The following command initializes the cluster on this node:

``` bash
sudo kubeadm init --pod-network-cidr=$POD_NETWORK --apiserver-advertise-address=$NODE_IP
```

If this succeeds, we should see information for joining other worker nodes to this cluster.
We won't do that at this point, but it's a sign that the command completed successfully.

To make kubectl work for our non-root user, run the following commands:

``` bash
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
```

## Install Flannel

Prepare the Manifest file:

``` bash
curl -sSOJ https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sed -i '/net-conf.json/,/}/{ s#10.244.0.0/16#'"$POD_NETWORK"'#; }' kube-flannel.yml
```

Apply the Manifest file:

``` bash
kubectl apply -f kube-flannel.yml
```

## Enable Pod Scheduling

By default, Kubernetes will not schedule Pods on the control-plane node for security reasons.
As we're running with a single Node, we need to remove the node-role.kubernetes.io/control-plane- taint, meaning that the scheduler will then be able to schedule Pods on it.

``` bash
kubectl taint node --all node-role.kubernetes.io/control-plane-
```

## Deploy Longhorn as the Default Persistent Storage

First create the longhorn-system namespace:
``` bash
kubectl create namespace longhorn-system
```
Then add the longhorn repository to helm:
``` bash
helm repo add longhorn https://charts.longhorn.io
```
Finally deploy Longhorn with all replica counts set to 1 and UI exposed on port 32100 via NodePort instead of ClusterIp:
``` bash
helm install longhorn longhorn/longhorn --version 1.3.1 \
--set service.ui.type=NodePort,\
service.ui.nodePort=32100,\
persistence.defaultClassReplicaCount=1,\
csi.attacherReplicaCount=1,\
csi.provisionerReplicaCount=1,\
csi.resizerReplicaCount=1,\
csi.snapshotterReplicaCount=1,\
defaultSettings.defaultReplicaCount=1,\
namespaceOverride="longhorn-system"
```

## A small busybox pod for testing

It is very convenient (however optional) to test the Kubernetes installation with a simple busybox pod for instance to test your DNS resolution inside a pod. To do so create the following yaml file (/tmp/busybox.yaml):

``` bash
cat << EOF > /tmp/busybox.yaml
apiVersion: v1
kind: Pod
metadata:
 name: busybox
 namespace: default
spec:
 containers:
 - name: busybox
   image: busybox:1.28
   command:
     - sleep
     - "3600"
   imagePullPolicy: IfNotPresent
 restartPolicy: Always
EOF
```

Then you can create the pod:
NOTE : --kubeconfig is optional here because ```$HOME/.kube/config``` is the default config file

``` bash
kubectl --kubeconfig $HOME/.kube/config create -f /tmp/busybox.yaml
```

If all went well a new POD was created, you can verify this with the following command

``` bash 
kubectl --kubeconfig $HOME/.kube/config get pods
#NAME      READY STATUS    RESTARTS AGE
#busybox   1/1 Running   21 21h
```

In order to verify if your Kubernetes is working correctly you could try some simple commands using the busybox POD. 
For instance to verify your name resolution works do:

``` bash 
kubectl exec -ti busybox -- nslookup mirrors.ubuntu.com 
#Server:    10.96.0.10
#Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
 
#Name:      mirrors.ubuntu.com
#Address 1: 91.189.89.32 bilimbi.canonical.com
```
 
## Remove in full a Kubernetes installation

On occasion, it may be deemed necessary to fully remove Kubernetes, for instance if for any reason your server IP address will change, then the advertised Kubernetes IP address will have to follow. THe following command help making sure the previous installation is cleared up: 


``` bash 
sudo kubeadm reset
sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube*
sudo rm -rf ~/.kube
sudo rm -rf /etc/cni/net.d
sudo ip link delete cni0
sudo ip link delete flannel.1
```


