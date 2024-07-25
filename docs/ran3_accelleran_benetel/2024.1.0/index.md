# RAN3: AccelleranDU-Benetel

> PS: All the following steps and sections won't be needed in case of using ansible. Guide available in [5G Integration Repo](https://github.com/accelleran/5g-integration/tree/main/utilities/install_tools/ansible)


| RAN | Component | Version |
|-|-|-|
| RAN3 | Accelelran DU | 1.0.4 |
| RAN3 | BNTL650-CATA | RAN650-1v1.0.4-dda1bf5 |

<p align="center">
  <img src="04_RAN3_Overview.png">
</p>

## 1. DU Server Changes

- Make sure to add the public key of the cell wrapper to the server's authorized keys in `.ssh/authorized_keys`

### 1.1. Sync DU Server with PTP

There are multiple options to sync the RU and DU

- Details on this can be found in [DU-RU Timing Synchronization](../../du-ru_sync_options/2024.1.0/index.md)

### 1.2. DPDK and Fronthaul Preperation

- Install DPDK 23.11
```bash
mkdir -p ~/accelleran/installation_files
sudo apt update
sudo apt -y install build-essential tar wget
sudo apt -y install python3-pip libnuma-dev meson ninja-build python3-pyelftools
cd ~/accelleran/installation_files
wget https://fast.dpdk.org/rel/dpdk-23.11.tar.xz
tar xvf dpdk-23.11.tar.xz dpdk-23.11/
cd dpdk-23.11/ && sudo meson setup build
cd build/ && sudo ninja
sudo meson install
sudo ldconfig
```

- Update below script with PF,VF,VF_IF,VF_MAC,VF_PCI (VF=VirtualFunction)
> PS: To find the PCI addr one can use: `lshw -c network -businfo`

```bash
mkdir -p ~/accelleran
tee ~/accelleran/deploy_dpdk.sh <<EOF
#!/bin/sh

export P_INTERFACE="enp1s0f3"
export VF_ID=0
export VF="enp1s0f3v0"
export VF_MAC="ee:c0:21:77:cc:92"
export VF_PCI="0000:01:0e.0"

log() {
	echo "$(date) ${1}"
}

log "setting up link"
sudo ip link set dev $P_INTERFACE vf $VF_ID trust on
sudo ip link set $P_INTERFACE promisc on
sudo ip link set $P_INTERFACE allmulticast on
sudo ip link set $VF promisc on
sudo ip link set $VF allmulticast on

sudo ethtool $P_INTERFACE --set-priv-flags vf-true-promisc-support on

log "disabling spoof check"
sudo ip link set $P_INTERFACE vf 0 spoofchk off

log "assigning DU MAC address for VF"
sudo ip link set $P_INTERFACE vf $VF_ID mac $VF_MAC

log "increasing ring buffer size"
sudo ethtool -G $P_INTERFACE tx 4096 rx 4096
sudo ethtool -G $VF tx 4096 rx 4096

log "binding VF to dpdk"
sudo ifconfig $VF down
sudo dpdk-devbind.py --bind vfio-pci $VF_PCI

log "deploy_dpdk.sh script done"
EOF
chmod +x ~/accelleran/deploy_dpdk.sh
```

- Run the script once and then addd it to crontab if it is working correctly.
```
crontab -e
# Add below
@reboot ~/accelleran/deploy_dpdk.sh > /tmp/dpdk_init_log.txt
```


### 1.3. DU Image

- Make sure to login to docker on the DU server with a username that has access to dockerhub
```bash
docker login
```

- Optionaly, one can pull the image manually. (This will be done automatically with the cell wrapper)
```bash
docker pull accelleran/du:1.0.4
```


## 2. Fibrolan Switch Changes

> PS: Assuming VLAN ID 6 would be used for this testing setup.

- Make sure the Switch is connected to GPS source
- Configrure the VLAN Allowed for the Ports connected to the DU Side and The RU
	- (With Fibrolan Falcon Switch): Configuration -> VLANs -> Configuration. (as below image)
		- Mode: Trunk
		- Port VLAN: 1588
		- Egress Tagging: Untag Port VLAN 
		- Allowed VLANs: 1588,6
		<p align="center">
		<img src="00_Fibrolan_VLAN_Config.png">
		</p>

- Configure PTP Clock:
	- (With Fibrolan Falcon Switch): Configuration -> Timing -> PTP (as below image)
		- Create/Edit a lock. (Profile G8275.1)
		- Select the Ports towards the DU and RU
		- Dom: 24
		- VID: 1588
		<p align="center">
		<img src="00_Fibrolan_PTP_Config.png">
		</p>




## 2. Benetel Changes

- Make sure to add the public key of the cell wrapper to the unit's authorized keys in `.ssh/authorized_keys`

>**NOTE:** The rest of this section is only needed when cell wrapper is not used.

### 2.1. Set DU MAC Address

- Check the Fronthaul interface MAC address on the DU server side.
```bash
ifconfig eno1
```

- ssh into the RU and edit `/usr/sbin/radio_setup_a.sh` (lines 397,398,401,402). (assuming the mac address was `7c:c2:55:69:f8:e9`)
```bash
LOG_INFO "Set expected DU MAC Address for C-Plane Traffic (C0319/C031A)"
/usr/bin/registercontrol -w C031A -x 0x7cc2
/usr/bin/registercontrol -w C0319 -x 0x5569f8e9

LOG_INFO "Set expected DU MAC Address for U-Plane Traffic (C0315/C0316)"
/usr/bin/registercontrol -w C0316 -x 0x7cc2
/usr/bin/registercontrol -w C0315 -x 0x5569f8e9
```

### 2.2. Set VLAN

- ssh into the RU and edit `/usr/sbin/radio_setup_a.sh` (lines 411, 408, 405). (assuming the VLAN used is 6)
```bash
LOG_INFO "Set required DU VLAN Tag Control Information for uplink U-Plane Traffic (C0318)"
/usr/bin/registercontrol -w C0318 -x 0x6

LOG_INFO "Set expected DU VLAN Tag Control Information for downlink U-Plane Traffic (C0330)"
/usr/bin/registercontrol -w C0330 -x 0x6

LOG_INFO "Set expected DU VLAN Tag Control Information for downlink C-Plane Traffic (C0331)"
/usr/bin/registercontrol -w C0331 -x 0x6
```

### 2.3. Cell Related Parameters

- Edit `/etc/ru_config.cfg` and `/etc/tdd.xml` to match the needed configuration. 
- Example configs can be found on [Integration Github](https://github.com/accelleran/5g-integration/tree/main/configs/CW_BaseConfigs/DDDDDDDSUU_configA_Default/Accelleran-Benetel) 

### 2.4. Set Frequency and Bandwidth

- Set the frequency and the bandwidth with below commands: (assuming center frequency 3955.2MHz with 100Mz BW)
```bash
frequencycontrol -f 3955200000
set_bandwidth -b 100000000
```
