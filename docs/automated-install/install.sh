#!/bin/bash
#  Drax install script  


ROOT_UID=0     # Only users with $UID 0 have root privileges.
E_NOTROOT=87   # Non-root exit error.
E_WRONGVER=85   # Non-root exit error.


# Check all requirments
# Run as root, of course.
if [ "$UID" -ne "$ROOT_UID" ]
then
  echo "Must be root to run this script."
  exit $E_NOTROOT
fi  

# Check Ubuntu version
if [[ $(lsb_release -rs) != "20.04" ]]; then # replace xxxx by the number of release you want

  echo "This installer will only work on Ubuntu 20.04"
  exit $E_WRONGVER
fi


# Disable sleep
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Disable swap
swapoff -a
sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab

# Add some certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list


# Install some software packages
apt update -y
apt upgrade -y
apt install -y vim ssh linux-lowlatency git ethtool traceroute linux-tools-common tuned cpufrequtils

apt remove linux-image-generic
apt-mark hold kubelet kubeadm kubectl

apt autoremove
apt clean

# In order to avoid possible system performance degradation, CPU scaling must be disabled
echo 'GOVERNOR="performance"' | tee /etc/default/cpufrequtils
systemctl disable ondemand


# Start the wizard
while true
do
   echo "Enter the IP address of the node"
    read NODE_IP
    if [ ! -d $NODE_IP ]  ;
    then
         echo "ERROR: invalid ip"
     else
         echo "Node ip validated successfully.."
         break
     fi
done

while true
do
   echo "Enter the name of the network interface that has IP $NODE_IP"
    read NODE_INT
    if [ ! -d $NODE_INT ]  ;
    then
         echo "ERROR: invalid interface"
     else
         echo "Interface validated successfully.."
         break
     fi
done

while true
do
   echo "Enter the IP address of the gateway"
    read GATEWAY_IP
    if [ ! -d $GATEWAY_IP ]  ;
    then
         echo "ERROR: invalid gateway"
     else
         echo "Gateway validated successfully.."
         break
     fi
done

while true
do
   echo "Enter the Core IP address"
    read CORE_IP
    if [ ! -d $CORE_IP ]  ;
    then
         echo "ERROR: invalid CORE ip adress"
     else
         echo "CORE ip validated successfully.."
         break
     fi
done

while true
do
   echo "Enter CU IP address"
    read CU_IP
    if [ ! -d $CU_IP ]  ;
    then
         echo "ERROR: invalid CU ip"
     else
         echo "CU ip validated successfully.."
         break
     fi
done

while true
do
    echo "Enter Kubernetes POD Network (Example 10.244.0.0/16)"
    read POD_NETWORK
    if [ ! -d $POD_NETWORK ]  ;
    then
         echo "ERROR: invalid POD network"
     else
         echo "CU ip validated successfully.."
         break
     fi
done


export $NODE_IP      # the IP address of the node
export $NODE_INT     # name of the network interface that has IP $NODE_IP
export $GATEWAY_IP   # the IP address of the gateway
export $CORE_IP      # the IP address of the core
export $CU_IP        # the IP address of the CU
export $POD_NETWORK  # the Subnet of the pod network


# Docker configuration
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

systemctl enable docker
systemctl daemon-reload
systemctl restart docker

# Kubernetes install
apt install -y kubelet=1.20.0-00 kubeadm=1.20.0-00 kubectl=1.20.0-00
apt-mark hold kubelet kubeadm kubectl

kubeadm init --pod-network-cidr=$POD_NETWORK --apiserver-advertise-address=$NODE_IP

# Install Flannel
curl -sSOJ https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sed -i '/net-conf.json/,/}/{ s#10.244.0.0/16#'"$POD_NETWORK"'#; }' kube-flannel.yml

kubectl apply -f kube-flannel.yml

# Enable Pod Scheduling
kubectl taint nodes --all node-role.kubernetes.io/master-





exit 0
