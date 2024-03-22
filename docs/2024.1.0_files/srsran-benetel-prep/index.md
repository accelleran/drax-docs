# 8. srsRAN-Benetel Preparation

## **1. srsRAN Changes**

### 1.1. Load DU Image

> This section is only needed when cell wrapper is not used.

- login with docker
```bash
docker login
```

- pull the needed image from the repo.
```bash
docker pull accelleran/srsran-gnb:master
```

### 1.2. Sync DU Server with PTP

- Install linuxptp
```bash
sudo apt install linuxptp
```

- Assuming the interface connected to the switch is "eno1", run below commands.
> below example are using screen to keep the commands running after closing the terminal


```bash
screen -S ptp_sync
sudo ptp4l -2 -i eno1 -f default_ptp4.cfg -m &
sudo phc2sys -s eno1 -w -m -R 8 -f default_ptp4.cfg &
```

- Using [Attached configs](cell_configuraiton_files.zip) along with the configurations on [Integration Github](https://github.com/accelleran/5g-integration/tree/main/configs/products/srsRAN_du/benetel).
    - Make sure the cell configuration yml file is named gnb_config.yml


## **2. Benetel Changes**

- For all below changes, Reboot the RU to apply.

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
- Follow the configurations on [Integration Github](https://github.com/accelleran/5g-integration/tree/main/configs/products/srsRAN_du/benetel) 

### 2.4. Set Frequency and Bandwidth

- Set the frequency and the bandwidth with below commands: (assuming center frequency 3955.2MHz with 100Mz BW)
```bash
frequencycontrol -f 3955200000
set_bandwidth -b 100000000
```





