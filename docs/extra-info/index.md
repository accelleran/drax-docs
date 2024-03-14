# 10. Extra Info

## 1. Related to the Server Preperation

### 1.1. Unsupported SFP+ module type was detected
- Use information on this [link](https://www.serveradminz.com/blog/unsupported-sfp-linux/)

### 1.2. Virtual Functions Can't Be Used

- For example in cases where SR-IOV is not supported.
- Bridge Interface would need to be created on the server and then add NIC interfaces on the CU and CORE VMs to use it.

```bash
sudo apt install bridge-utils
sudo brctl addbr br0
```
- Assuming the baremetal server interface is called enp2s0f1, Adapt the server netplan to use a bridge and apply
```bash
network:
  ethernets:
    enp2s0f1:
      dhcp4: false
      optional: true

  bridges:
    br0:
      addresses: 
      - 10.55.5.2/24
      - 10.55.5.5/24
      gateway4: <>
      nameservers: 
        addresses: [<>]
      interfaces:
        - enp2s0f1
```
- With virt-manager GUI edit the VM: `Add Hardware` -> `Network`.
<p align="center">
  <img src="bridge_interface.png">
</p>

## 2. Related to Core

### 2.1. TCP Algorithm Parameter Change

- Edit `/etc/sysctl.conf` to include below:

```bash
# allow testing with buffers up to 64MB
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
# increase Linux autotuning TCP buffer limit to 32MB
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432
# change TCP congestion algorithm to BBR
net.ipv4.tcp_congestion_control = bbr
# recommended to use a 'fair queueing' qdisc
net.core.default_qdisc = fq
```

- Apply changes
```bash
sudo sysctl --system 
```


## 3. Related to Kubernetes

### 3.1. Remove in full a Kubernetes installation

On occasion, it may be deemed necessary to fully remove Kubernetes, for instance if for any reason your server IP address will change, then the advertised Kubernetes IP address will have to follow. THe following command help making sure the previous installation is cleared up: 

``` bash 
sudo kubeadm reset
sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni
sudo rm -rf ~/.kube
sudo rm -rf /etc/cni/net.d
sudo ip link delete cni0
sudo ip link delete flannel.1
```

