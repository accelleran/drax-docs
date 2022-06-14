

## Prerequisites
The RU needs at least version 2V0.6.0

```
oot@benetelru:~# cat /etc/benetel-rootfs-version 
RAN550-2V0.6.0
```

## Configuration

### Dawing
created in  https://asciiflow.com/

```
                                               CU
                                               IP : 10.10.0.1
                                              ┌─────────────────────┐
       RU                                     │                     │
       IP : 10.10.0.100                       │                     │
      ┌──────────┐                            │                     │
      │          │                            │                     │
      │          │                            │                     │
      │      eth0├────────────────────────────┤eno1                 │
      │          │    Fiber                   │                     │
      │          │                            │                     │
      │          │                            │                     │
      │          │                            │                     │
      └──────────┘                            │                     │
                                              │                     │
                                              │                     │
                                              │                     │
                                              └─────────────────────┘

```




## Server side
### Install ptp server

```
sudo apt update
sudo apt install linuxptp
```

### configuration file

```
cat << EOF > benetel550_ptp.cfg
[global]
domainNumber 24
twoStepFlag 1
assume_two_step 1
#masterOnly 1
announceReceiptTimeout 3
logAnnounceInterval 1
logSyncInterval -4
logMinDelayReqInterval -4
network_transport	L2
hybrid_e2e 1
EOF
```

### run the server 
```
sudo ptp4l -2 -E -f benetel550_ptp.cfg -i eno1 -m
```

-2 means that it is ethernet multicast packets that are being sent.
At this moment multicast messages will be sent on the interface ```eno1```

example of a tcpdump on the server
```
ad@duserver:~$ sudo tcpdump -i eno1 -en
[sudo] password for ad: 
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eno1, link-type EN10MB (Ethernet), capture size 262144 bytes
13:03:30.226015 ec:f4:bb:e3:b4:68 > 01:1b:19:00:00:00, ethertype Unknown (0x88f7), length 58: 
	0x0000:  0002 002c 1800 0200 0000 0000 0000 0000  ...,............
	0x0010:  0000 0000 ecf4 bbff fee3 b468 0001 74cc  ...........h..t.
	0x0020:  00fc 0000 0000 0000 0000 0000            ............
```


## RU side
### Commands to configure PTP
using : https://drive.google.com/drive/u/0/folders/17uyl3vpKXAO_9IMyiEKNQw0VpvLJvVxe

Below the command to execute to use PTP to sync

```
root@benetelru:~# setSyncModePtp.sh

57 settings written to SMU
RU Set to use PTP on next reboot. Reboot for this to take effect.
```

### trace ethernet packets

tracing ethernet packets on the RU
```
oot@benetelru:~# tcpdump -i eth0 ether proto 0x88f7
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
12:31:00.865296 ec:f4:bb:e3:b4:68 (oui Unknown) > 01:1b:19:00:00:00 (oui Unknown), ethertype Unknown (0x88f7), length 78: 
	0x0000:  0b02 0040 1800 0008 0000 0000 0000 0000  ...@............
	0x0010:  0000 0000 ecf4 bbff fee3 b468 0001 0000  ...........h....
	0x0020:  0501 0000 0000 0000 0000 0000 0025 0080  .............%..
	0x0030:  f8fe ffff 80ec f4bb fffe e3b4 6800 00a0  ............h...
```

### restart sync
``` systemctl restart ru_sync ```

### logs

```
tail -f /var/log/pcm4l
```

this is a succesful sync. It first shows the drift and ends with Time and Freq locked to Yes.
```
E::SyncAnalysis: 2020-02-11 19:34:02 373837860 ns [3, Tracker#0] (3240) offset: -355.0 ns    delay: 262.0 ns  
RE::SyncAnalysis: 2020-02-11 19:34:02 437792660 ns [3, Tracker#0] (3240) offset: -370.5 ns    delay: 262.5 ns  
RE::SyncAnalysis: 2020-02-11 19:34:02 497767860 ns [3, Tracker#0] (3240) offset: -389.5 ns    delay: 266.5 ns  
RE::SyncAnalysis: 2020-02-11 19:34:02 561789160 ns [3, Tracker#0] (3240) offset: -403.0 ns    delay: 265.0 ns  
       :
RE::SyncAnalysis: 2020-02-11 19:34:06 001791300 ns [3, Tracker#0] (3240) offset: 0.0 ns    delay: 269.0 ns  
RE::SyncAnalysis: 2020-02-11 19:34:07 377794460 ns [3, Tracker#0] (3240) offset: 0.0 ns    delay: 269.0 ns  
       :
RE::Debug: 2020-02-11 19:34:07 695880440 ns [2, Supervisor] Enter time locked state  
RE::Debug: 2020-02-11 19:34:07 696391520 ns [2, Supervisor] Tracker#0:  
RE::Debug: 2020-02-11 19:34:07 701360020 ns [2, Supervisor] 	Master port ID: ec:f4:bb:ff:fe:e3:b4:68.1  
RE::Debug: 2020-02-11 19:34:07 701947880 ns [2, Supervisor] 	Current reference master: Yes  
RE::Debug: 2020-02-11 19:34:07 702461120 ns [2, Supervisor] 	Freq locked: Yes  
RE::Debug: 2020-02-11 19:34:07 702870420 ns [2, Supervisor] 	Time locked: Yes  
``` 


### reboot the RU 

rebooting the RU will make the RU sync 
The indication of ```Sync Completed``` in this file indicates sync is succesful

```
root@benetelru:~# cat /tmp/logs/radio_status 
[INFO] Platform: RAN550_B
[INFO] Radio bringup begin
[INFO] Initialize TDD Pattern
[INFO] Load EEPROM Data
[INFO] Tx1 Attenuation set to 05580 mdB
[INFO] Tx3 Attenuation set to 07660 mdB
[INFO] Operating Frequency set to 3601.920 MHz
[INFO] Waiting for Sync
[INFO] Sync completed
[INFO] Kick off Synchronization of Linux system time to PTP time
[INFO] Start Radio Configuration
```
another file indicates the success aswell.
```
root@benetelru:~# cat /tmp/logs/radio_sync_status 
Configuring CP60 for PTP Sync Mode
PTP Settings configured
Directory /usr/lib/benetel OK
Directory /usr/lib/benetel/splane OK
Directory /usr/lib/benetel/splane/flags OK
todsync started
PTP4L started
PCM4L started
Syncmon started
Waiting for initial PTP sync...
PTP locked, enabling holdover functionality.
```
