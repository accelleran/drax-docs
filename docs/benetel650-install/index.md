# Summary
## Drawing

```
  10.10.0.100:ssh
  +-------------+
  |             |
  |             |             +-----------+         +-----------+
  |             |             |           |         |           |
  |     RRU     +----fiber----+   L1      |         |    DU     |
  |             |             |           |         |           |
  |             |             +-----------+         +-----------+
  |             |
  +-------------+
aa:bb:cc:dd:ee:ff              11:22:33:44:55:66

  10.10.0.2:44000              10.10.0.1:44000

             eth0              enp45s0f0

      port FIBER1
```

             
## Configure the DU

Other then the B210, benetel uses 2 software components. 2 Containers, a effnet du and phluido l1.
The phluido rru is not needed. This component resides in the benetel equipment.

adapt the `PhluidoL1_NR_Benetel.cfg` file delivered by effnet
Make sure to set the value `LicenseKey` option to the received Phluido license key:

``` bash
to be tested which .cfg to use
```

Create a configuration file for the Effnet DU:

``` bash
to be tested which .json to use
```

Before creating the `docker-compose.yml` file, make sure to set the `$CU_IP` environment variable.
This IP address can be determined by executing the following command.
The CU address is the second IP address.
This IP address should be in the IP pool that was assigned to MetalLB in [dRax Installation](/drax-docs/drax-install/).

``` bash
kubectl get services | grep 'acc-5g-cu-cp-.*-sctp-f1'
```

Now, create a docker-compose configuration file:

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2021-06-30/docker-compose.yml <<EOF
version: "3"

services:

  phluido_l1:
    image: phluido_l1
    container_name: phluido_l1_cn
    tty: true
    privileged: true
    ipc: shareable
    shm_size: 2gb
    command: /config.cfg
    volumes:
      - "$PWD/phluido/PhluidoL1_NR_B210.cfg:/config.cfg:ro"
      - "$PWD/logs/l1:/workdir"
      - "/etc/machine-id:/etc/machine-id:ro"
    working_dir: "/workdir"
    network_mode: host

  du:
    image: gnb_du_main_phluido
    volumes:
      - "$PWD/b210_config_20mhz.json:/config.json:ro"
      - "$PWD/logs/du:/workdir"
      - /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm
    ipc: container:phluido_l1_cn
    tty: true
    cap_add:
      - CAP_SYS_NICE
      - CAP_IPC_LOCK
    depends_on:
      - phluido_l1
    entrypoint: ["/bin/sh", "-c", "sleep 4 && exec /gnb_du_main_phluido /config.json"]
    working_dir: "/workdir"
    extra_hosts:
      - "cu:$CU_IP"

EOF
```


## Prepare the Benetel 650


Add mac entry script in routable.d. 

```
$ cat /etc/networkd-dispatcher/routable.d/macs.sh 
#!/bin/sh
sudo arp -s 10.10.0.2 aa:bb:cc:dd:ee:ff -i enp45s0f0
```
> Benetel650 does not answer arp requests. With this apr entry in the arp table the server knows to which mac address it needs to sent the ip packet to. The ip packet towards the RRU with ip 10.10.0.2.
>


The benetel is connected with a fiber to the server. The port on the RRU is labeled ```port FIBER1```

``` bash
:ad@5GCN:~$ lshw | grep SFP -C 5
WARNING: you should run this program as super-user.
             capabilities: pci normal_decode bus_master cap_list
             configuration: driver=pcieport
             resources: irq:29 ioport:f000(size=4096) memory:f8000000-f86fffff
           *-network:0 DISABLED
                description: Ethernet interface
                product: 82599ES 10-Gigabit SFI/SFP+ Network Connection
                vendor: Intel Corporation
                physical id: 0
                bus info: pci@0000:2d:00.0
                logical name: enp45s0f0
                version: 01
--
                capabilities: bus_master cap_list rom ethernet physical fibre 10000bt-fd
                configuration: autonegotiation=off broadcast=yes driver=ixgbe driverversion=5.1.0-k firmware=0x2b2c0001 latency=0 link=no multicast=yes
                resources: irq:202 memory:f8000000-f807ffff ioport:f020(size=32) memory:f8200000-f8203fff memory:f8080000-f80fffff memory:f8204000-f8303fff memory:f8304000-f8403fff
           *-network:1 DISABLED
                description: Ethernet interface
                product: 82599ES 10-Gigabit SFI/SFP+ Network Connection
                vendor: Intel Corporation
                physical id: 0.1
                bus info: pci@0000:2d:00.1
                logical name: enp45s0f1
                version: 01
```

by setting both network devices to UP you find out which one is connected.
In our case its enp45s0f0.

``` bash
:ad@5GCN:~$ sudo ip link set dev enp45s0f0 up
:ad@5GCN:~$ sudo ip link set dev enp45s0f1 up
:ad@5GCN:~$ ip -br a
	:
enp45s0f0        UP             fe80::6eb3:11ff:fe08:a4e0/64 
enp45s0f1        DOWN           
	:
```

configuring the static ip of enp45s0f0 is done via netplan.
add this part to `/etc/netplan/50-cloud-init.yaml` . 
In some installation it might be anot 

``` bash

network:
    ethernets:
       enp45s0f0:
          dhcp4: false
          dhcp6: false
          optional: true
          addresses:
              - 10.10.0.1/24
          mtu: 9000
```

To apply this configuration you can use

``` bash
sudo netplan apply 
```

This needs to be the result

``` bash
$ ip -br a | grep enp45
enp45s0f0        UP             10.10.0.1/24 fe80::6eb3:11ff:fe08:a4e0/64 
enp45s0f1        DOWN           
```

The ip benetel is configured with is `10.10.0.100`. This is the MGMT ip. We can ssh to it.
We found out using nmap this way.

``` bash
$ nmap 10.10.0.0/24

Starting Nmap 7.60 ( https://nmap.org ) at 2021-09-21 10:15 CEST
Nmap scan report for 10.10.0.1
Host is up (0.000040s latency).
Not shown: 996 closed ports
PORT     STATE SERVICE
22/tcp   open  ssh
111/tcp  open  rpcbind
5900/tcp open  vnc
9100/tcp open  jetdirect

Nmap scan report for 10.10.0.100
Host is up (0.0053s latency).
Not shown: 998 closed ports
PORT    STATE SERVICE
22/tcp  open  ssh
111/tcp open  rpcbind

Nmap done: 256 IP addresses (2 hosts up) scanned in 3.10 seconds

```

A route is added also in the route table automatically

``` bash
$ route -n | grep 10.10.0.0
10.10.0.0       0.0.0.0         255.255.255.0   U     0      0        0 enp45s0f0
````

now you can ssh to the benetel

``` bash
$ ssh root@10.10.0.100

Last login: Fri Feb  7 16:45:59 2020 from 10.10.0.1
root@benetelru:~# ls -l
-rwxrwxrwx    1 root     root          1572 Sep 10  2021 DPLL3_1PPS_REGISTER_PATCH.txt
drwxrwxrwx    2 root     root             0 Feb  7 16:44 adrv9025
-rwxrwxrwx    1 root     root          1444 Feb  7 16:40 dev_struct.dat
-rwxrwxrwx    1 root     root         17370 Sep 10  2021 dpdModelReadback.txt
-rwxrwxrwx    1 root     root          5070 Feb  7 17:00 dpdModelcoefficients.txt
-rwxrwxrwx    1 root     root         24036 Sep 10  2021 eeprog_cp60
-rwxrwxrwx    1 root     root       1825062 Feb  7 15:58 madura_log_file.txt
-rw-------    1 root     root          1230 Feb  7  2020 nohup.out
-rwxr-xr-x    1 root     root            57 Feb  7  2020 nohup_handshake
-rwxrwxrwx    1 root     root           571 Feb  7  2020 progBenetelDuMAC_CATB
-rwxr-xr-x    1 root     root       1121056 Feb  7 16:24 quickRadioControl
-rwxrwxrwx    1 root     root       1151488 Sep 10  2021 radiocontrol_prv-nk-cliupdate
-rwxrwxrwx    1 root     root         22904 Aug 24  2021 registercontrol
-rwxrwxrwx    1 root     root           164 Feb  7 16:35 removeResetRU_CATB
-rwxrwxrwx    1 root     root           163 Feb  7  2020 reportRuStatus
-rwxrwxrwx    1 root     root           162 Feb  7 16:35 resetRU_CATB
-rwxr-xr-x    1 root     root            48 Feb  7 15:57 runSync
-rwxrwxrwx    1 root     root         21848 Sep 10  2021 smuconfig
-rwxrwxrwx    1 root     root         17516 Sep 10  2021 statmon
-rwxrwxrwx    1 root     root         23248 Sep 10  2021 syncmon
-rwxr-xr-x    1 root     root           182 Feb  7 16:41 trialHandshake
root@benetelru:~# 
```

## Version Check
finding out the version and commit hash of the benetel650

commit hash
```
root@benetelru:~# registercontrol -v
Lightweight HPS-to-FPGA Control Program Version : V1.2.0

****BENETEL PRODUCT VERSIONING BLOCK****
This Build Was Created Locally. Please Use Git Pipeline!
Project ID NUMBER: 	0
Git # Number: 		f6366d7adf84933ab2b242a345bd63c07fedb9e5
Build ID: 		0
Version Number: 	0.0.1
Build Date: 		2/12/2021
Build Time H:M:S: 	18:20:3
****BENETEL PRODUCT VERSIONING BLOCK END****
```
The version which is referred to. This is version 0.4. 
Depending on the version different configuration commands apply.
```
root@benetelru:~# cat /etc/benetel-rootfs-version 
RAN650-2V0.4
```

## Configure the RRU release V0.3
### Set DU mac address for version V0.3


Inside the file ```/etc/radio_init.sh``` we program the mac. 

Example for MAC address 00:1E:67:FD:F5:51 you will find in the file:

    registercontrol -w c0315 -x 0x67FDF551 >> /home/root/radio_boot_response 
    registercontrol -w c0316 -x 0x001E >> /home/root/radio_boot_response
    echo "Configure the MAC address of the O-DU: 00:1E:67:FD:F5:51 " >> /home/root/radio_status 

Make sure to edit those as MAC address of the fiber port.

Reboot the BNTL650



### Set the Frequency for version V0.3


This file ```/etc/systemd/system/multi-user.target.wants/autoconfig.service``` is called during boot that sets the frequency.
change the frequency here.

```
[Service]
ExecStart =/bin/sh /etc/radio_init.sh 3751.680
```

Example for frequency 3751.68MHz (ARFCN=650112) you will find in the file:
Make sure to edit the pointA frequency ARFCN value in the DU config (in this example PointA_ARFCN=648840).

Reboot the BNTL650

## Configure the RRU release V0.4
### Set DU mac address in the RRU

Create this script to program the mac address of the DU inside the RRU. Remember the RRU does not request arp, so we have to manually configure that.

```
root@benetelru:~# cat progDuMAC-5GCN-enp45s0f0 
# 11:22:33:44:55:66  5GCN-itf
registercontrol -w 0xC036B -x 0x88000088                            # don't touch file
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1A:0x01:0x11             # first byte of mac address is 0x11
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1B:0x01:0x22             # etc ...
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1C:0x01:0x33
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1D:0x01:0x44
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1E:0x01:0x55
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1F:0x01:0x66
```

### Set the Frequency for version v0.4

This file ```/etc/systemd/system/multi-user.target.wants/autoconfig.service``` is called during boot that sets the frequency.

```
[Service]
ExecStart =/bin/sh /etc/radio_init.sh $(read_default_tx_frequency)
```

In this version the frequency is read from the eeprom. So we program the eeprom with the correct center frequency.
Programming the eeprom with the center frequency we do with this script.

```
root@benetelru:~# cat progFreq

registercontrol -w 0xC036B -x 0x88000088                            # don't touch file
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x174:0x01:0x33
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x175:0x01:0x37
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x176:0x01:0x35
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x177:0x01:0x31
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x178:0x01:0x2E
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x179:0x01:0x36
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17A:0x01:0x38
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17B:0x01:0x30

eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17C:0x01:0x33
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17D:0x01:0x37
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17E:0x01:0x35
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17F:0x01:0x31
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x180:0x01:0x2E
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x181:0x01:0x36
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x182:0x01:0x38
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x183:0x01:0x30

eeprog_cp60 -f -16 /dev/i2c-0 0x57 -r 0x174:8
eeprog_cp60 -f -16 /dev/i2c-0 0x57 -r 0x17C:8
```

Each byte 0x33,0x37,0x35, ... is the ascii value of a numbers 3751,680

### Set attenuation level
1. read current attenuations
```
~# radiocontrol -o G a

Benetel radiocontrol Version          : 0.9.0
Madura API Version                    : 5.1.0.21
Madura ARM FW version                 : 5.0.0.32
Madura ARM DPD FW version             : 5.0.0.32
Madura Stream version                 : 8.0.0.5
Madura Product ID                     : 0x84
Madura Device Revision                : 0xb0
Tx1 Attenuation (mdB)                 : 20000
Tx2 Attenuation (mdB)                 : 40000
Tx3 Attenuation (mdB)                 : 21000
Tx4 Attenuation (mdB)                 : 40000
PLL1 Frequency (Hz)                   : 0 
PLL2 Frequency (Hz)                   : 3751680000 
Front-end Control                     : 0x2aa491
Madura Deframer 0                     : 0x87
Madura Framer 0                       : 0xa
Internal Temperature (degC)           : 47
External Temperature (degC)           : 42.789063
RX1 Power Level (dBFS)                : -60.750000
RX2 Power Level (dBFS)                : -60.750000
RX3 Power Level (dBFS)                : -60.750000
RX4 Power Level (dBFS)                : -60.750000
ORX1 Peak/Mean Power Level (dBFS)     : -10.839418/-22.709361
ORX2 Peak/Mean Power Level (dBFS)     : -inf/-inf
ORX3 Peak/Mean Power Level (dBFS)     : -10.748048/-21.656226
ORX4 Peak/Mean Power Level (dBFS)     : -inf/-inf
```
2. set attenuation for antenna 1
```
/usr/bin/radiocontrol -o A 20000 1
```
3. set attenuation for antenna 3
```
/usr/bin/radiocontrol -o A 21000 4
```
>yes the 4 at the end seems to be correct.



## Configure for any RRU release
### Set RRU mac address in DU server
 
 
 
## Throubleshoot 



### GPS
See if GPS is locked
```
root@benetelru:~# syncmon
DPLL0 State (SyncE/Ethernet clock): LOCKED
DPLL1 State (FPGA clocks): FREERUN
DPLL2 State (FPGA clocks): FREERUN
DPLL3 State (RF/PTP clock): LOCKED

CLK0 SyncE LIVE: OK
CLK0 SyncE STICKY: LOS + No Activity
CLK2 10MHz LIVE: LOS + No Activity
CLK2 10MHz STICKY: LOS + No Activity
CLK5 GPS LIVE: OK
CLK5 GPS STICKY: LOS and Frequency Offset
CLK6 EXT 1PPS LIVE: LOS and Frequency Offset
CLK6 EXT 1PPS STICKY: LOS and Frequency Offset
```
### To be noted
some important registers
```
root@benetelru:~# reportRuStatus 

[INFO] Sync status is: 
Register 0xc0367, Value : 0x1
-------------------------------

[INFO] RU Status information is: 
Register 0xc0306, Value : 0x470800
-------------------------------

[INFO] Fill level of Reception Window is: 
Register 0xc0308, Value : 0x6c12
-------------------------------

[INFO] Sample Count is: 
Register 0xc0311, Value : 0x56f49
-------------------------------


============================================================
RU Status Register description:
============================================================
[31:19] not used                                                        
[18]    set to 1 if handshake is successful                             
[17]    set to 1 when settling time (fronthaul) has  completed 
[16]    set to 1 if symbolndex=0 was captured                           
[15]    set to 1 if payload format is invalid                           
[14]    set to 1 if symbol index error has been detected                
[13:12] not used                                                        
[11]    set to 1 if DU MAC address is correct                           
[10:2]  not used                                                        
[1]     Reception Window Buffer is empty                                
[0]     Reception Window Buffer is full                                 
------------------------------------------------------------
===========================================================
[NOTE] Max buffer  depth is 53424 (112 symbols, 2 antennas)
===========================================================
```

trace traffic between RRU and L1. Also the mac can be read from this trace. Packet lengths are 3874. 
Remember we increased the MTU size to 9000. Without increasing the L1 would crash on the fragmented udp packets.

```
$ tcpdump -i enp45s0f0 -c 5 port 44000 -en
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp45s0f0, link-type EN10MB (Ethernet), capture size 262144 bytes
19:22:47.096453 02:00:5e:01:01:01 > 6c:b3:11:08:a4:e0, ethertype IPv4 (0x0800), length 64: 10.10.0.2.44000 > 10.10.0.1.44000: UDP, length 20
19:22:47.106677 6c:b3:11:08:a4:e0 > 02:00:5e:01:01:01, ethertype IPv4 (0x0800), length 54: 10.10.0.1.44000 > 10.10.0.2.44000: UDP, length 12
19:23:14.596247 02:00:5e:01:01:01 > 6c:b3:11:08:a4:e0, ethertype IPv4 (0x0800), length 64: 10.10.0.2.44000 > 10.10.0.1.44000: UDP, length 12
19:23:14.596621 6c:b3:11:08:a4:e0 > 02:00:5e:01:01:01, ethertype IPv4 (0x0800), length 3874: 10.10.0.1.44000 > 10.10.0.2.44000: UDP, length 3832
19:23:14.596631 6c:b3:11:08:a4:e0 > 02:00:5e:01:01:01, ethertype IPv4 (0x0800), length 3874: 10.10.0.1.44000 > 10.10.0.2.44000: UDP, length 3832
5 packets captured
```

Check if the L1 is listening 
```
$ while true ; do sleep 1 ; netstat -ano | grep 44000 ;echo $RANDOM; done
udp        0 118272 10.10.0.1:44000         0.0.0.0:*                           off (0.00/0/0)
1427
udp        0  16896 10.10.0.1:44000         0.0.0.0:*                           off (0.00/0/0)
11962
udp        0  42240 10.10.0.1:44000         0.0.0.0:*                           off (0.00/0/0)
16780
udp        0      0 10.10.0.1:44000         0.0.0.0:*                           off (0.00/0/0)
502
```

Show the traffic between rru and du

```
$ ifstat -i enp45s0f0
    enp45s0f0     
 KB/s in  KB/s out
71320.01  105959.7
71313.36  105930.1
```

### Troubleshooting Fiber Port not showing up
https://www.serveradminz.com/blog/unsupported-sfp-linux/


## Starting RRU Benetel 650
Perform these steps to get a running active cell.

1) Start L1
2) Start DU  
   At this point following sequence is 
```
     DU                                        CU
      |  F1SetupRequest--->                     |
      |                    <---F1SetupResponse  |
      |			                        |
      |	          <---GNBCUConfigurationUpdate  |
      |                                         |
```
   The L1 starts listening on ip:port 10.10.0.1:44000

3) type ```ssh root@10.10.0.100  handshake```
   After less than 30 seconds communication between rru and du starts. around 100 Mbytes/second
 
```
     DU                                        CU
      |  GNBCUConfigurationUpdateAck--->        |
      |                                         |
```

5) type ```ssh root@10.10.0.100 handshake``` again to stop the traffic. ( If it does not stop use ```ssh_rru "registercontrol -w c0310 -x 0 ``` but be carefull )

 
