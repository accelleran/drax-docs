# CU installation ( VM & kubernetes )
## Table of Content
- [CU installation ( VM & kubernetes )](#cu-installation--vm--kubernetes-)
  - [Table of Content](#table-of-content)
  - [Introduction](#introduction)
    - [VM Minimum Requirements](#vm-minimum-requirements)
  - [Configure HOST server](#configure-host-server)
    - [set a linux bridge](#set-a-linux-bridge)
  - [Install VM](#install-vm)
    - [console using command line](#console-using-command-line)
    - [console using virt-manager](#console-using-virt-manager)
      - [screen 1 - basic mode](#screen-1---basic-mode)
      - [screen 2 - Continue without updating](#screen-2---continue-without-updating)
      - [screen 3 - English US keyboard](#screen-3---english-us-keyboard)
      - [screen 4 and 5 - Set static ip](#screen-4-and-5---set-static-ip)
      - [screen 6 - proxy](#screen-6---proxy)
      - [screen 7 - archive mirror](#screen-7---archive-mirror)
      - [screen 8 and 9 - storage configuration](#screen-8-and-9---storage-configuration)
      - [screen 10 and 11 - are you sure](#screen-10-and-11---are-you-sure)
      - [screen 12 - profile setup](#screen-12---profile-setup)
      - [screen 13 - enable ubuntu advantage](#screen-13---enable-ubuntu-advantage)
      - [screen 14 - install openSSH server](#screen-14---install-openssh-server)
      - [screen 15 - Featured server snaps](#screen-15---featured-server-snaps)
      - [screen 16 - installation starts](#screen-16---installation-starts)
      - [screen 17 - install complete](#screen-17---install-complete)
    - [Install Docker in the CU VM](#install-docker-in-the-cu-vm)
    - [Configure Docker Daemon](#configure-docker-daemon)
    - [Disable Swap](#disable-swap)
    - [Install Kubernetes inside the VM](#install-kubernetes-inside-the-vm)
    - [Configure Kubernetes](#configure-kubernetes)
    - [Install Flannel](#install-flannel)
    - [Enable Pod Scheduling](#enable-pod-scheduling)
    - [A small busybox pod for testing](#a-small-busybox-pod-for-testing)
  - [APENDIX : Remove a full Kubernetes installation](#apendix--remove-a-full-kubernetes-installation)

## Introduction
This chapter will install the CU, using Flannel for the CNI.
This guide defaults to using Docker as the container runtime.
For more information on installing Kubernetes, see the [official Kubernetes documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/).

This chapter will guide you through following steps : 
* install VM ( with cpu pinning )
* install docker in the CU VM
* install kubernetes in the CU VM


### VM Minimum Requirements
1. 8 dedicated Cores    ( cpuset planned in the preperation chapter ) 
2. 32GB DDR4 RAM
3. 200GB Hard Disk      ( includes space for logging/monitor/debugging the system )

## Configure HOST server


### set a linux bridge
create a linux bridge using netplan

adapt your netplan file assuming that $SERVER_INT holds the physical interface name of your server
that connects to the network.


``` bash
network:
  ethernets:
    $SERVER_INT:
      dhcp4: false
  :
  :
  bridges:
    br0:
      interfaces: [$SERVER_INT]
      addresses:
            - $SERVER_IP/24
      gateway4: $GATEWAY_IP
      nameservers:
        addresses: [8.8.8.8]

  version: 2

```
on the host uncomment the line in ```/etc/sysctl.conf``` so you get this.

``` bash
net.ipv4.ip_forward=1
```

reboot the host.

## Install VM

If not yet installed install

```bash
sudo apt install virtinst
sudo apt install libvirt-clients
sudo apt install qemu
sudo apt install qemu-kvm
sudo apt install libvirt_daemon
sudo apt install bridge-utils
sudo apt install virt-manager
```

** reboot server **

Below a command line that creates a VM with the correct settings.

> IMPORTANT ! the $CORE_SET_CU can only be a comma seperated list. 

```bash
sudo virt-install  --name "$CU_VM_NAME"  --memory 16768 --vcpus "sockets=1,cores=$CORE_AMOUNT_CU,cpuset=$CORE_SET_CU"  --os-type linux  --os-variant rhel7.0 --accelerate --disk "/var/lib/libvirt/images/CU-ubuntu-20.04.4-live-server-amd64.img,device=disk,size=100,sparse=yes,cache=none,format=qcow2,bus=virtio"  --network "source=br0,type=bridge" --vnc  --noautoconsole --cdrom "./ubuntu-20.04.4-live-server-amd64.iso"  --console pty,target_type=virtio
```

> some notes about this command
> * --noautoconsole : if you ommit this, a graphical console window will popup. This works only when the remote server can export its graphical UI to your local graphical environment like an X-windows
> * --console pty,target_type=virtio will make sure you can use ```virsh console $CU_VM_NAME```

Continue in the console the complete the VM installation.
### console using command line
```
virsh console $CU_VM_NAME
```
> NOTE ! This can take a few minutes before you see something appearing

### console using virt-manager
start on your local machine virt-manager. 
connect to the remote baremetal server using the ip $SERVER_IP.
You will see the virtual machine $CU_VM_NAME listed. 
double click it and proceed.

#### screen 1 - basic mode

select basic mode

```
================================================================================
  Serial                                                              [ Help ]
================================================================================
                                                                              
  As the installer is running on a serial console, it has started in basic    
  mode, using only the ASCII character set and black and white colours.       
                                                                              
  If you are connecting from a terminal emulator such as gnome-terminal that  
  supports unicode and rich colours you can switch to "rich mode" which uses  
  unicode, colours and supports many languages.                               
                                                                              
  You can also connect to the installer over the network via SSH, which will  
  allow use of rich mode.                                                     
                                                                            
                          [ Continue in rich mode  > ]                        
                          [ Continue in basic mode > ]                        
                          [ View SSH instructions    ]                        
```

#### screen 2 - Continue without updating
select "Continue without updating"

```
================================================================================
  Installer update available                                          [ Help ]
================================================================================
  Version 22.07.2 of the installer is now available (22.02.2 is currently     
  running).                                                                   
                                                                              
  You can read the release notes for each version at:                         
                                                                              
                 https://github.com/canonical/subiquity/releases              
                                                                              
  If you choose to update, the update will be downloaded and the installation 
  will continue from here.                                                    
                                                                              
                        [ Update to the new installer ]                       
                        [ Continue without updating   ]                       
                        [ Back                        ]                       
```

#### screen 3 - English US keyboard

select Engligh US keyboard

```
================================================================================
  Keyboard configuration                                              [ Help ]
================================================================================
  Please select the layout of the keyboard directly attached to the system, if
  any.                                                                        
                                                                              
                 Layout:  [ English (US)                     v ]              
                                                                              
                                                                              
                Variant:  [ English (US)                     v ]              
                                                                              
                                 [ Done       ]                               
                                 [ Back       ]                               
```

#### screen 4 and 5 - Set static ip
* select Edit IPv4
* Set the subnet, ip, gateway and name servers in the next screen
* select Done
```
================================================================================
  Network connections                                                 [ Help ]
================================================================================
  Configure at least one interface this server can use to talk to other       
  machines, and which preferably provides sufficient access for updates.      
                                                                              
    NAME    TYPE  NOTES             ┌───────────────────┐                     
  [ ens3    eth   -                >│< (close)          │                     
    static  10.22.11.148/24         │  Info            >│                     
    52:54:00:68:47:29 / Red Hat, Inc│  Edit IPv4       >│vice                 
                                    │  Edit IPv6       >│                     
  [ Create bond > ]                 │  Add a VLAN tag  >│                     
                                    └───────────────────┘                     
                                                                              
                                 [ Done       ]                               
                                 [ Back       ]                               

================================================================================
  Network connections                                                 [ Help ]
================================================================================

   ┌───────────────────── Edit ens3 IPv4 configuration ─────────────────────┐
   │                                                                        │
   │  IPv4 Method:   [ Manual           v ]                              ^  │
   │                                                                     │  │
   │                                                                     │  │
   │          Subnet:  $NODE_SUBNET                                      │  │
   │                                                                     │  │
   │                                                                     │  │
   │         Address:  $NODE_IP                                          │  │
   │                                                                     │  │
   │                                                                     |  │
   │         Gateway:  $GATEWAY_IP                                       |  │
   │                                                                     |  │
   │    Name servers:  8.8.8.8                                           │  │
   │                   IP addresses, comma separated                     │  │
   │                                                                     │  │
   │  Search domains:                                                    │  │
   │                   Domains, comma separated                          v  │
   │                                                                        │
   │                                                                        │
   │                             [ Save       ]                             │
   │                             [ Cancel     ]                             │
   │                                                                        │
   └────────────────────────────────────────────────────────────────────────┘
```
#### screen 6 - proxy
* Select Done
```
================================================================================
  Configure proxy                                                     [ Help ]
================================================================================
  If this system requires a proxy to connect to the internet, enter its       
  details here.                                                               
                                                                              
  Proxy address:                                                              
                  If you need to use a HTTP proxy to access the outside world,
                  enter the proxy information here. Otherwise, leave this     
                  blank.                                                      
                                                                              
                  The proxy information should be given in the standard form  
                  of "http://[[user][:pass]@]host[:port]/".                   
                                                                              
                                 [ Done       ]                               
                                 [ Back       ]                               

```

#### screen 7 - archive mirror
* select Done
```
================================================================================
  Configure Ubuntu archive mirror                                     [ Help ]
================================================================================
  If you use an alternative mirror for Ubuntu, enter its details here.        
                                                                              
  Mirror address:  http://be.archive.ubuntu.com/ubuntu                        
                   You may provide an archive mirror that will be used instead
                   of the default.                                            
                                                                              
                                 [ Done       ]                               
                                 [ Back       ]                               

```

#### screen 8 and 9 - storage configuration
* select Done 
* select Done
```
================================================================================
  Guided storage configuration                                        [ Help ]
================================================================================
  Configure a guided storage layout, or create a custom one:                  
                                                                              
  (X)  Use an entire disk                                                     
                                                                              
       [ /dev/vda local disk 256.000G v ]                                     
                                                                              
       [X]  Set up this disk as an LVM group                                  
                                                                              
            [ ]  Encrypt the LVM group with LUKS                              
                                                                              
                         Passphrase:                                          
                                                                              
                                                                              
                 Confirm passphrase:                                          
                                                                              
                                                                              
  ( )  Custom storage layout                                                  
                                                                              
                                 [ Done       ]                               
                                 [ Back       ]                               

================================================================================
  Storage configuration                                               [ Help ]
================================================================================
  FILE SYSTEM SUMMARY                                                        ^
                                                                             │
    MOUNT POINT     SIZE    TYPE      DEVICE TYPE                            │
  [ /             100.000G  new ext4  new LVM logical volume      > ]        │
  [ /boot           1.500G  new ext4  new partition of local disk > ]        │
                                                                             │
                                                                             │
  AVAILABLE DEVICES                                                          │
                                                                             │
    DEVICE                                   TYPE                 SIZE        
  [ ubuntu-vg (new)                          LVM volume group   254.496G  > ] 
    free space                                                  154.496G  >   
                                                                              
  [ Create software RAID (md) > ]                                             
  [ Create volume group (LVM) > ]                                             
                                                                             v
                                                                              
                                 [ Done       ]                               
                                 [ Reset      ]                               
                                 [ Back       ]                               

```

#### screen 10 and 11 - are you sure
* select Continue

```
   ┌────────────────────── Confirm destructive action ──────────────────────┐
   │                                                                        │
   │  Selecting Continue below will begin the installation process and      │
   │  result in the loss of data on the disks selected to be formatted.     │
   │                                                                        │
   │  You will not be able to return to this or a previous screen once the  │
   │  installation has started.                                             │
   │                                                                        │
   │  Are you sure you want to continue?                                    │
   │                                                                        │
   │                             [ No         ]                             │
   │                             [ Continue   ]                             │
   │                                                                        │
   └────────────────────────────────────────────────────────────────────────┘
```
#### screen 12 - profile setup
* enter your name, the name of the person that does this installation
* enter the server name $CU_VM_NAME
* enter the username $USER
* enter the password
* Select Done

```
  Profile setup                                                       [ Help ]
▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
  Enter the username and password you will use to log in to the system. You   
  can configure SSH access on the next screen but a password is still needed  
  for sudo.                                                                   
                                                                              
              Your name:  Dennis                                              
                                                                              
     Your server's name:  testvm                                              
                          The name it uses when it talks to other computers.  
                                                                              
        Pick a username:  ad                                                  
                                                                              
      Choose a password:  *********                                           
                                                                              
  Confirm your password:  *********                                           
                                                                              
                                 [ Done       ]                               
```
#### screen 13 - enable ubuntu advantage
* select Done

```
================================================================================
  Enable Ubuntu Advantage                                             [ Help ]
================================================================================
  Enter your Ubuntu Advantage token if you want to enroll this system.        
                                                                              
  Ubuntu Advantage token:                                                     
                           If you want to enroll this system using your Ubuntu
                           Advantage subscription, enter your Ubuntu Advantage
                           token here. Otherwise, leave this blank.           
          
                                 [ Done       ]                               
                                 [ Back       ]                               
```

#### screen 14 - install openSSH server
* select Install openSSH server
```
================================================================================
  SSH Setup                                                           [ Help ]
================================================================================
  You can choose to install the OpenSSH server package to enable secure remote
  access to your server.                                                      
                                                                              
                   [X]  Install OpenSSH server                                
                                                                              
                                                                              
  Import SSH identity:  [ No             v ]                                  
                        You can import your SSH keys from GitHub or Launchpad.
                                                                              
      Import Username:                                                        
                                                                              
                                                                              
                   [X]  Allow password authentication over SSH                
                                                                              
                                                                              
                                 [ Done       ]                               
                                 [ Back       ]                               
```

#### screen 15 - Featured server snaps
* don't select any extra feature
* select Done
```
================================================================================
  Featured Server Snaps                                               [ Help ]
================================================================================
  These are popular snaps in server environments. Select or deselect with     
  SPACE, press ENTER to see more details of the package, publisher and        
  versions available.                                                         
                                                                              
  [ ] microk8s            Kubernetes for workstations and appliances        >^
  [ ] nextcloud           Nextcloud Server - A safe home for all your data  >│
  [ ] wekan               The open-source kanban                            >│
  [ ] kata-containers     Build lightweight VMs that seamlessly plug into t >│
  [ ] docker              Docker container runtime                          >│
  [ ] canonical-livepatch Canonical Livepatch Client                        >│
  [ ] rocketchat-server   Rocket.Chat server                                >│
  [ ] mosquitto           Eclipse Mosquitto MQTT broker                     > 
  [ ] etcd                Resilient key-value store by CoreOS               > 
  [ ] powershell          PowerShell for every system!                      > 
  [ ] stress-ng           tool to load and stress a computer                > 
  [ ] sabnzbd             SABnzbd                                           > 
  [ ] wormhole            get things from one computer to another, safely   >v
                                                                              
                                 [ Done       ]                               
                                 [ Back       ]                               
```

#### screen 16 - installation starts
wait like around 5 minutes for the installation to complete

```
================================================================================
  Installing system                                                   [ Help ]
================================================================================
  ┌──────────────────────────────────────────────────────────────────────────┐
  │          configuring iscsi service                                       │
  │          configuring raid (mdadm) service                                │
  │          installing kernel                                               │
  │          setting up swap                                                 │
  │          apply networking config                                         │
  │          writing etc/fstab                                               │
  │          configuring multipath                                           │
  │          updating packages on target system                              │
  │          configuring pollinate user-agent on target                      │
  │          updating initramfs configuration                                │
  │          configuring target system bootloader                            │
  │          installing grub to target devices                               │
  │    finalizing installation                                               │
  │      running 'curtin hook'                                               │
  │        curtin command hook                                               │
  │    executing late commands  /                                            │
  └──────────────────────────────────────────────────────────────────────────┘

                               [ View full log ]
```

#### screen 17 - install complete
* select reboot now
```
================================================================================
  Install complete!                                                   [ Help ]
================================================================================
  ┌──────────────────────────────────────────────────────────────────────────┐
  │    finalizing installation                                              ^│
  │      running 'curtin hook'                                               │
  │        curtin command hook                                               │
  │    executing late commands                                               │
  │final system configuration                                                │
  │  configuring cloud-init                                                  │
  │  calculating extra packages to install                                   │
  │  installing openssh-server                                               │
  │    curtin command system-install                                         │
  │  downloading and installing security updates                             │
  │    curtin command in-target                                              │
  │  restoring apt configuration                                             │
  │    curtin command in-target                                              │
  │    curtin command in-target                                             ││
  │subiquity/Late/run                                                       v│
  └──────────────────────────────────────────────────────────────────────────┘

                               [ View full log ]
                               [ Reboot Now    ]
```
Wait untill you can click reboot server

> NOTE : if after some minutes the server has not rebooted yet you have to reboot it  forcefully like this. Most likely the cdrom fails to unmount.
>
> ``` 
> virsh reset $CU_VM_NAME 
> ```

ssh into the VM.

``` bash
ssh $USER@$NODE_IP
```

from inside this VM you should be able to ping the internet's ip address 8.8.8.8

``` bash
ping 8.8.8.8
```

make sure all available disk space is being used inside the VM.
```
lsblk
sudo lvextend -r -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
lsblk
```

Every heading that follows has to be done inside this VM.

### Install Docker in the CU VM

Add the Docker APT repository:

``` bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```
```
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
```
sudo apt update
```

Install the required packages:

``` bash
sudo apt install docker-ce 
```
```
sudo apt install docker-ce-cli 
```
```
sudo apt install containerd.io 
```
```
sudo apt install docker-compose
```

Add your user to the docker group to be able to run docker commands without sudo access.
You might have to reboot or log out and in again for this change to take effect.

``` bash
sudo usermod -aG docker $USER
sudo reboot
```

To check if your installation is working you can try to run a test image in a container:

``` bash
docker run hello-world
```

### Configure Docker Daemon

The recommended configuration of the Docker daemon is provided by the Kubernetes team - particularly to use systemd for the management of the container's cgroups:

``` bash
sudo mkdir /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
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

Restart Docker and enable on boot:

``` bash
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Disable Swap

Kubernetes refuses to run if swap is enabled on the node, so we disable swap immediately and then also disable it following a reboot:

``` bash
sudo swapoff -a
sudo sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab
```

### Install Kubernetes inside the VM

Add the Kubernetes APT repository:

``` bash
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
```

Accelleran dRAX currently supports Kubernetes up to version 1.20. The following command installs specifically this version:

``` bash
sudo apt install -y kubelet=1.20.0-00 kubeadm=1.20.0-00 kubectl=1.20.0-00
```
``` bash
sudo apt-mark hold kubelet kubeadm kubectl
```

### Configure Kubernetes

To initialize the Kubernetes cluster, the IP address of the node needs to be fixed, i.e. if this IP changes, a full re-installation of Kubernetes will be required.
This is generally the (primary) IP address of the network interface associated with the default gateway.
From here on, this IP is referred to as `$NODE_IP` - we store it as an environment variable for later use:

``` bash
export NODE_IP=x.x.x.x         # See Preperation paragraph for correct ip
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

### Install Flannel

Prepare the Manifest file:

``` bash
curl -sSOJ https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sed -i '/net-conf.json/,/}/{ s#10.244.0.0/16#'"$POD_NETWORK"'#; }' kube-flannel.yml
```

Apply the Manifest file:

``` bash
kubectl apply -f kube-flannel.yml
```

### Enable Pod Scheduling

By default, Kubernetes will not schedule Pods on the control-plane node for security reasons.
As we're running with a single Node, we need to remove the node-role.kubernetes.io/master taint, meaning that the scheduler will then be able to schedule Pods on it.

``` bash
kubectl taint nodes --all node-role.kubernetes.io/master-
```

### A small busybox pod for testing

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
 
## APENDIX : Remove a full Kubernetes installation

On occasion, it may be deemed necessary to fully remove Kubernetes, for instance if for any reason your server IP address will change, then the advertised Kubernetes IP address will have to follow. THe following command help making sure the previous installation is cleared up: 


``` bash 
sudo kubeadm reset
```
``` bash
sudo apt-get purge kubeadm 
```
``` bash
sudo apt-get purge kubectl 
```
``` bash
sudo apt-get purge kubelet
```
``` bash
sudo apt-get purge kubernetes-cni
```
``` bash
sudo rm -rf ~/.kube
```
``` bash
sudo rm -rf /etc/cni/net.d
```
``` bash
sudo ip link delete cni0
```
``` bash
sudo ip link delete flannel.1
```



