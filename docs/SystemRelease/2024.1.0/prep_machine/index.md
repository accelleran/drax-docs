# Server preparation

## 1. Mandatory Steps

- This guide will follow the [Example Network Diagram](/drax-docs/SystemRelease/2024.1.0/#3-example-network-components-overview)
- Also, below CPU allocation would be used:
<p align="center">
  <img src="/drax-docs/images/02_cpu_allocation.png">
</p>

> PS:

> - This is based on the `AMD Ryzen 9 7950X 16-Core Processor` used with the lab super micro servers. But depending on the CPU this might be different.
> - This is intended to be used for single machine setups for testing purposes. (Customer setups would have a seperate machine to run the CU/RIC/CORE)

### 1.1. Prepare the Machine for RealTime Performance

> These changes are needed to run any DU tested in our lab, Plus the VMs.

- On The BIOS Settings:
    - System Profile Settings:
        - System Profile -> Performance
    - Integrated Devices Settings:
        - SR-IOV Global Enable -> Enabled
        - USB 3.0 Settings -> Enabled

- Install lowlatency kernel
```bash
sudo apt update
sudo apt install linux-image-lowlatency
sudo apt remove linux-image-generic
sudo apt autoremove
```
- Configure the OS scheduler to be more responsive
```bash
sudo sh -c "echo 100000 > /sys/kernel/debug/sched/min_granularity_ns"
sudo sh -c "echo 20000 > /sys/kernel/debug/sched/wakeup_granularity_ns"
sudo sh -c "echo 500000 > /sys/kernel/debug/sched/latency_ns"
echo "sched_rt_runtime_us = -1" | sudo tee -a /etc/sysctl.conf
echo "fs.mqueue.msg_max = 64" | sudo tee -a /etc/sysctl.conf
sudo sysctl --system 
```

- As some of the OS parameters are not reboot persistant create a crontab job to run them after reboot
```bash
mkdir -p ~/accelleran
tee ~/accelleran/set-scheduler-settings.sh <<EOF
#!/bin/sh
sudo sh -c "echo 100000 > /sys/kernel/debug/sched/min_granularity_ns"
sudo sh -c "echo 20000 > /sys/kernel/debug/sched/wakeup_granularity_ns"
sudo sh -c "echo 500000 > /sys/kernel/debug/sched/latency_ns"
EOF
chmod +x ~/accelleran/set-scheduler-settings.sh
```
```bash
crontab -e
# Add below
@reboot ~/accelleran/set-scheduler-settings.sh
```

- Disable CPU scaling
```bash
sudo apt install cpufrequtils
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
sudo systemctl disable ondemand
```

### 1.2. Isolate CPU Cores for the DU

- To isolate the needed DU/L1 cores, Edit `/etc/default/grub` file to include below: (update the isolated cores according to the need)
```bash
GRUB_CMDLINE_LINUX="processor.max_cstate=1 intel_idle.max_cstate=0 intel_pstate=passive hugepagesz=1G hugepages=4 hugepagesz=2M hugepages=4 default_hugepagesz=1G intel_iommu=on iommu=pt selinux=0 enforcing=0 nmi_watchdog=0 audit=0 mce=off kthread_cpus=0 irqaffinity=0 isolcpus=8-15,24-31 nosoftlockup nohz=on nohz_full=8-15,24-31 rcu_nocbs=8-15,24-31 skew_tick=1"
GRUB_FLAVOUR_ORDER=lowlatency
```
- To Apply run below:
```bash
sudo update-grub2 
```



### 1.3. Prepare Virtual Functions

- Create Virtual Function Interfaces on your Server to be used later on by the CU and CORE VMs.
- Make sure the server interface can support Virtual Functions. This is by checking if the NIC can allow SR_IOV. More details mentioned [here](../../../extra_info/index.md)
```bash
sudo lspci -vvv | less 
cat /sys/class/net/enp2s0f1/device/sriov_numvfs
```
- Assuming the above is valid, virtual-functions can be created by editing the netplan to include below:
```bash
network:
  ethernets:
    enp2s0f1:
      virtual-function-count: 4
```
- After applying this, new interfaces would appear on the server. (enp2s0f1v0, enp2s0f1v1, enp2s0f1v2, enp2s0f1v3). Update the netplan again to include the IP to be used by the DU on one of these interfaces.
```bash
network:
  ethernets:
    enp2s0f1v2:
      addresses:
      - 10.55.5.5/24
```

### 1.4. Create Virtual Machines

Use below steps to create two VMs on the machine and connect it to the baremetal server.

- Install virt-manager on the baremetal server
```bash
sudo apt install virt-manager
```
- Download ubuntu22.04 server iso. (example below command)
```bash
curl -O https://releases.ubuntu.com/22.04.4/ubuntu-22.04.4-live-server-amd64.iso
```

#### Using virt-manager GUI

- ssh into the baremetal server using -X. and fire up virt-manager
```bash
ssh -X username@10.55.5.2
virt-manager
```
- Follow the steps and vreate the VM using ubuntu 22.04 server iso, Keep in mind:
    - The VM would be using cores other than those isolated for the DU in section 1.2 above.
        - To achieve this make sure to click on `Customise configuration before install`
        <p align="center">
        <img src="/drax-docs/images/03_vm_install_customize.png">
        </p>
        - Edit the XML to change the cpu line to be as below:`  <vcpu placement="static" cpuset="2-6,18-22">10</vcpu>`
        <p align="center">
        <img src="/drax-docs/images/03_vm_install_edit_xml.png">
        </p>
        - Remove default created NIC device and then from `Add Hardware` -> `PCI Host Device` select the Virtual function created for this virtual machine.
        <p align="center">
        <img src="/drax-docs/images/03_vm_add_pci.png">
        </p>    
        - The below should be the default , but Please make sure the CPU configuration is using "host-passthough".
        <p align="center">
        <img src="/drax-docs/images/03_vm_cpu_passthrough.png">
        </p>    

## 2. Automated Preparation Using Ansible

- All the following steps and sections won't be needed in case of using ansible.
- Please follow the guide in [5G Integration Repo](https://github.com/accelleran/5g-integration/tree/main/utilities/install_tools/ansible)




## 3. Manual Server Preparation

### 3.1. Install Docker

From (https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

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
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose

sudo usermod -aG docker $USER
```

- logout and login for the last command to take effect

```bash
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
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

- Optionally, one can update docker-compose to the latest version. (It might be needed in cases when to operate the cell without the cell-wrapper). More information can be found in [link](https://docs.docker.com/compose/install/linux/#install-the-plugin-manually)

```bash
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.28.1/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
sudo chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
# to overwite the version installed in earlier
sudo cp $DOCKER_CONFIG/cli-plugins/docker-compose /usr/bin/.
```

### 3.2. Vendor Specific Steps
* [EffnetDU-Phluido Preparation](/drax-docs/effnet_phluido_benetel/2024.1.0/)
* [AccelleranDU Preparation](/drax-docs/accelleran_benetel/2024.1.0/)
