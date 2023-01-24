## Prepare and bring on air the Benetel 650 Radio

This section is exclusively applicable to the user/customer that intends to use the Benetel B650 Radio End with our Accellleran 5G end to end solution, if you do not have such radio end the informations included in this section may be misleading and bring to undefined error scenarios. Please contact Accelleran if your Radio End is not included in any section of this user guide

#### Diagram

In the picture below we schematically show what will be run on the server by Docker and how the RRU is linked to the server itself: as mentioned early in this case the two components run by Docker are the L1 and the DU, while the RRU is supposedly served by a dedicated NIC Card capable of handling a 10 Gbps fiber link. If this is not your case please consult the section dedicted to Ettus B210 bring up or contact Accelleran for further information 

```
  10.10.0.100:ssh
  +-------------+
  |             |
  |             |             +-----------+         +-----------+
  |             |             |           |         |           |
  |     RU      +----fiber----+   L1      |         |    DU     |
  |             |             |           |         |           |
  |             |             +-----------+         +-----------+
  |             |
  +-------------+
aa:bb:cc:dd:ee:ff              11:22:33:44:55:66

  10.10.0.2:44000              10.10.0.1:44000

             eth0              enp45s0f0

      port FIBER1
```

#### Frequency, Offsets, Point A Calculation

During your testing activity you may need to adjust the TX/Rx frequency of your End to End System and to do so you need to take into account that more than one component requires adjustments in its configuration:

- The RU requires the Center Frequency in MHz, both on RX and TX to be witten in the EEPROM
- The DU requires the Offset to Point A as ARFCN

This goal of this section is to proceed correctly and determine the exact parameters that will allow the Benetel Radio to go on air  and the UEs to be able to see the cell and attempt an attach so it is particularly important to proceed carefully on this point. There are currently several limitations on the Frequencies that go beyond the simple definition of 5G NR Band:

- the selected frequency should be above 3700 MHz 
- the selected band can be B77 or B78
- the selected frequency must be devisable by 3.84
- the K_ssb must be 0
- the offset to point A must be 6
- all the subcarriers shal be 30 KHz

Let's proceed with an example:

We want to set a center frequency of 3750 MHz, this is not devisable by 3.84, the first next frequencies that meet this condition are 3747,84 (976*3.84) 3751.68 (977*3,84) so let's consider first 3747,84 MHz and verify the conditions on the K_ssb and Offset to Point A with this online tool (link at:  (https://www.sqimway.com/nr_refA.php) ) 

- We remember to set the Band 78, SCs at 30 KHz, the Bandwidth at 40 MHz and the ARFCN of the center frequency 3747,84 which is 649856 and when we hit the **RUN** button we obtain:

<p align="center">
  <img width="600" height="800" src="../../du-install/Freq3747dot84.png">
</p>

This Frequency, however does not meet the **GSCN Synchronisation requirements** as in fact the Offset to Point A of the first channel is 2 and the K_ssb is 16, this will cause the UE to listen on the wrong channel so the SIBs will never be seen and therefore the cell is "invisible"

- We then repeat the exercise with the higher center frequency 3751,68 MHz, which yelds a center frequency ARFCN of 650112 and a point A ARFCN of 648840 and giving another run we will see that now the K_ssb and the Offset to Point A are correct:

<p align="center">
  <img width="600" height="800" src="../../du-install/Freq3751dot68.png">
</p>

With these information at hand we are going to determine:

* point A frequency : 3732.60  ( arfcn : 648840 ) - edit du configuration in the appropriate json file
* center Frequency  : 3751.68  ( arfcn : 650112 ) - edit RU configuration directly on the Benetel Radio End (see next sections)

At this point, you need to redeploy the Cell Wrapper with the modified ARFCN and write the new Tx and Rx Frequencies on the RU EEPROM. If you are uncertain on how to proceed, but you have calculated the correct frequencies and ARFCN please contact Accelleran to proceed on those modifications

### Prepare to configure the Benetel 650

The benetel is connected with a fiber to the server. 
1. The port on the physical B650 RRU is labeled ```port FIBER1```
2. The port on the server, depending on where you inserted the Fiber SFP+ Connector is one of these listed below.

``` bash
$ lshw | grep SFP -C 5
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
In this example it's enp45s0f0. This port is the one we connected the fiber to.

``` bash
:ad@5GCN:~$ sudo ip link set dev enp45s0f0 up
:ad@5GCN:~$ sudo ip link set dev enp45s0f1 up
```
Double check the result

``` bash
$ ip -br a | grep enp45
enp45s0f0        UP             10.10.0.1/24 fe80::6eb3:11ff:fe08:a4e0/64 
enp45s0f1        DOWN           
```

The default ip of the benetel radio is `10.10.0.100`. This is the MGMT ip. We can ssh to it as root@10.10.0.100 without password
We can anyway find that IP out using nmap 

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
Now you can ssh to the benetel

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
However, as mentioned, that above is the management IP address, whereas for the data interface the Benetel RU has a different MAC on 10.10.0.2 for instance ```70:b3:d5:e1:53:f0 ``` 

now check if the entry for 10.10.0.2 is in the arp table.

``` bash
$ arp -a | grep 10.10.
? (10.10.0.100) at 70:b3:d5:e1:53:b1 [ether] on br0
? (10.10.0.2) at 70:b3:d5:e1:53:f0 [ether] PERM on enp45s0f0
```

If not, add it using the onboard script:

``` bash
/etc/networkd-dispatcher/routable.d/macs.sh'
``` 

test the automatic execution of ```macs.sh``` by running
```
journalctl -f
```

and plugging in the fiber. Each time it is plugged in you will see the the execution of the ```arp``` which has been put in the macs.sh script above.
	
### Version Check
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
The version which is referred to. This is version 0.3. 
Depending on the version different configuration commands apply.
```
root@benetelru:~# cat /etc/benetel-rootfs-version 
RAN650-2V0.3
```


### Configure the physical Benetel Radio End - Release V0.5.x

There are several parameters that can be checked and modified by reading writing the EEPROM, for this we recommend to make use of the original Benetel Software User Guide for RANx50-02 CAT-B O-RUs, in case of doubt ask for clarification to Accelleran Customer Support . Here we just present two of the most used parameters, that will need an adjustment for each deployment.

#### CFR enabled 
By default the RU ships with CFR enabled. What still needs to be done is set register ```0366``` to value ```0xFFF```. 
Do this by altering file ```/usr/sbin/radio_setup_ran650_b.sh``` with following line.

``` bash
    registercontrol -w c0366 -x 0xFFF >> ${LOG_RAD_STAT_FP}
```



#### MAC Address of the DU

Create this script to program the mac address of the DU inside the RRU. Remember the RRU does not request arp, so we have to manually configure that. If the MAC address of the server port you use to connect to the Benetel B650 Radio End (the NIC Card port where the fiber originates from) is $MAC_DU 11:22:33:44:55:66 then you can program the EEPROM of your B650 unit as follows:

Here the value of ```$MAC_DU ``` need to be used.

Run this on the bare metal host server to generate the script that will run in the RU to set the mac.
``` bash
echo "
registercontrol -w 0xC036B -x 0x88000088
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1a:0x01:0x$(echo $MAC_DU | cut -c1-2)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1b:0x01:0x$(echo $MAC_DU | cut -c4-5)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1c:0x01:0x$(echo $MAC_DU | cut -c7-8)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1d:0x01:0x$(echo $MAC_DU | cut -c10-11)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1e:0x01:0x$(echo $MAC_DU | cut -c13-14)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1f:0x01:0x$(echo $MAC_DU | cut -c16-17)
registercontrol -w 0xC036B -x 0x88000488
"
```

Something like this will get generated. Copy and Paste this generated script into the RU.
``` bash
registercontrol -w 0xC036B -x 0x88000088
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1a:0x01:0x11
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1b:0x01:0x22
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1c:0x01:0x33
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1d:0x01:0x44
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1e:0x01:0x55
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1f:0x01:0x66
registercontrol -w 0xC036B -x 0x88000488
```
Login in the RU

``` bash
ssh root@$RU_MGMT_IP
```

and paste the script here.

You can read the EEPROM now and double check what you did:

```
eeprog_cp60 -q -f -x -16 /dev/i2c-0 0x57 -x -r 26:6
```

!! Finally, **reboot**  your Radio End to make the changes effective


#### Set the Frequency of the Radio End 
Create this script to program the Center Frequency in MHz of your B650 RRU. Remember to determine a valid frequency as indicated previously in the document, taking into account all the constraints and the relationship to the Offset Point A. If the Center Frequency you want to is for instance 3751,680 MHz then you can program the EEPROM of your B650 unit as follows:

Run the below script on the bare metal host. It will product a script that needs to run on the RU.

```
echo"
registercontrol -w 0xC036B -x 0x88000088
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x174:0x01:0x3$(echo $FREQ_CENTER | cut -c1)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x175:0x01:0x3$(echo $FREQ_CENTER | cut -c2)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x176:0x01:0x3$(echo $FREQ_CENTER | cut -c3)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x177:0x01:0x3$(echo $FREQ_CENTER | cut -c4)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x178:0x01:0x2E
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x179:0x01:0x3$(echo $FREQ_CENTER | cut -c6)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17A:0x01:0x3$(echo $FREQ_CENTER | cut -c7)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17B:0x01:0x3$(echo $FREQ_CENTER | cut -c8)
registercontrol -w 0xC036B -x 0x88000488

registercontrol -w 0xC036B -x 0x88000088                     
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17C:0x01:0x3$(echo $FREQ_CENTER | cut -c1)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17D:0x01:0x3$(echo $FREQ_CENTER | cut -c2)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17E:0x01:0x3$(echo $FREQ_CENTER | cut -c3)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17F:0x01:0x3$(echo $FREQ_CENTER | cut -c4)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x180:0x01:0x2E
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x181:0x01:0x3$(echo $FREQ_CENTER | cut -c6)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x182:0x01:0x3$(echo $FREQ_CENTER | cut -c7)
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x183:0x01:0x3$(echo $FREQ_CENTER | cut -c8)
registercontrol -w 0xC036B -x 0x88000488
"
```

The script that is produces looks like this.
```
echo"
registercontrol -w 0xC036B -x 0x88000088
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x174:0x01:0x33
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x175:0x01:0x37
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x176:0x01:0x35
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x177:0x01:0x31
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x178:0x01:0x2E
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x179:0x01:0x36
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17A:0x01:0x38
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17B:0x01:0x30
registercontrol -w 0xC036B -x 0x88000488

registercontrol -w 0xC036B -x 0x88000088
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17C:0x01:0x33
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17D:0x01:0x37
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17E:0x01:0x35
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x17F:0x01:0x31
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x180:0x01:0x2E
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x181:0x01:0x36
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x182:0x01:0x38
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x183:0x01:0x30
registercontrol -w 0xC036B -x 0x88000488

"
```

Verify the script if it has the ascii codes for the frequency digits.


Each byte 0x33,0x37,0x35, ... is the ascii value of a numbers 3751,680, often the calculation stops at two digits after the comma, consider the last digit always as a zero

You may then want to double check what you did by reading the EEPROM:

```
eeprog_cp60 -q -f -16 /dev/i2c-0 0x57 -r 372:8
```
 Copy/Paste this script and run in in the RU.
ssh to the RU and pasted it.

``` bash
ssh root@$RU_MGMT_IP
```

Once again, this is the 

**CENTER FREQUENCY IN MHz that we calculated in the previous sections, and has to go hand in hand with the point A Frequency as discussed above**

Example for frequency 3751.68MHz (ARFCN=650112) you have set make sure to edit/check the pointA frequency ARFCN value back in the DU config json file in the server (in this example PointA_ARFCN=648840)

**Reboot the BNTL650 to make changes effective**

When the RU comes online ( 5 minutes ) run the following to see what the new frequency shows.

``` bash
ssh root$RU_MGMT_IP
radiocontrol -o G a
```

#### Set attenuation level
This operation allows to temporary modify the attenuation of the transmitting channels of your B650 unit. Temporarily means that at the next reboot the Cell will default to the originally calibrated values, by default the transmission power is set to 25 dBm hence the attenuation is 15000 mdB (offset to the max TX Power). 

To adjust this power for the transmitter the user must edit the attenuation setting:

- For increasing the power the attenuation must be reduced
- For decreasing the power, the attenuation must be increased



**IMPORTANT NOTE: As of now, channel 2 and 4 are off and are not up for modification please do not try and modify those attenuation parameters**

So if we want, for instance, to REDUCE the Tx Power by 5 dB, we will then INCREASE the attenuation by 5000 mdB. Let's consider that each cell is calibrated individually so the first thing to do is to take note of the default values and offset from there to obtained the desired TX Power per channel

So here are the steps:

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
Tx1 Attenuation (mdB)                 : 16100
Tx2 Attenuation (mdB)                 : 40000
Tx3 Attenuation (mdB)                 : 15800
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
We can then conclude that our Antenna has been originally calibrated to have +1100 mdB on channel 1 and +800 mdB to obtain exactly 25 dBm Tx power on those chanels, so that we will then offset our 5000 dBm of extra attenuation and therefore the new attenuation levels are Tx1=16100+5000=21100 mdB and Tx2=15800+5000=20800mdB

2. set attenuation for antenna 1
```
/usr/bin/radiocontrol -o A 21100 1
```
3. set attenuation for antenna 3
```
/usr/bin/radiocontrol -o A 20800 4
```
**yes the 4 at the end seems to be correct**
**Bear in mind these settings will stay as long as you don't reboot the Radio and default back to the original calibration values once you reboot the unit**

4. assess the new status of your radio:

```
~# radiocontrol -o G a

Benetel radiocontrol Version          : 0.9.0
Madura API Version                    : 5.1.0.21
Madura ARM FW version                 : 5.0.0.32
Madura ARM DPD FW version             : 5.0.0.32
Madura Stream version                 : 8.0.0.5
Madura Product ID                     : 0x84
Madura Device Revision                : 0xb0
Tx1 Attenuation (mdB)                 : 21100
Tx2 Attenuation (mdB)                 : 40000
Tx3 Attenuation (mdB)                 : 20800
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

### Configure the physical Benetel Radio End - Older then Release V0.7.0

#### auto reset dpd

For releases older then V0.7.0 the dpd has to get reset every 30 minutes. This is not yet built inside and has to get created manually. These 3 steps need to be done.

* create these 2 files by copy/past the below
``` bash
cat <<EOF > /lib/systemd/system/dpd_reset.service
[Unit]
Description=Start DPD reset every 30 mins
After=eth0ipset.service

[Service]
Type=forking
ExecStart=/bin/sh /usr/sbin/dpd_reset.sh 

[Install]
WantedBy=multi-user.target

EOF

cat <<EOF > /usr/sbin/dpd_reset.sh
#! /bin/sh
while true 
do 
    sleep 1800
    date '+%Y-%m-%d %H:%M:%S ##########'
     cd /home/root; radiocontrol -o D r 15 1
done >> /tmp/dpd_reset_status &
EOF
chmod 777 /usr/sbin/dpd_reset.sh


```

* enable the service that just has been defined.
```
systemctl enable dpd_reset.service
```
* and start the service
```
systemctl start dpd_reset.service
```




## Starting RU Benetel 650 - manual way

### prepare cell


When the CELL is OFF this traffic can be in this state shown below.

```
ifstat -i $SERVER_RU_INT
     enp1s0f0     
 KB/s in  KB/s out
71308.34  0.0
71318.21  0.0
```

In this case execute

```
$ ssh root@10.10.0.100 handshake
```

After execution you will have 

```
ifstat -i $SERVER_RU_INT
     enp1s0f0     
 KB/s in  KB/s out
 0.0      0.0
 0.0      0.0
```

In this traffic state the dell is ready to start.

### start cell
Bring the components up with docker compose

``` bash
cd ~/install-$DU_VERSION/  
docker-compose up -f docker-compose-B650.yml
```

If all goes well this will produce output similar to:

```
Starting phluido_l1 ... done
Recreating accelleran-du-phluido-2022-01-31_du_1 ... done
Attaching to phluido_l1, accelleran-du-phluido-2022-01-31_du_1
phluido_l1  | Reading configuration from config file "/config.cfg"...
phluido_l1  | *******************************************************************************************************
phluido_l1  | *                                                                                                     *
phluido_l1  | *  Phluido 5G-NR virtualized L1 implementation                                                        *
phluido_l1  | *                                                                                                     *
phluido_l1  | *  Copyright (c) 2014-2020 Phluido Inc.                                                               *
phluido_l1  | *  All rights reserved.                                                                               *
phluido_l1  | *                                                                                                     *
phluido_l1  | *  The User shall not, and shall not permit others to:                                                *
phluido_l1  | *   - integrate Phluido Software within its own products;                                             *
phluido_l1  | *   - mass produce products that are designed, developed or derived from Phluido Software;            *
phluido_l1  | *   - sell products which use Phluido Software;                                                       *
phluido_l1  | *   - modify, correct, adapt, translate, enhance or otherwise prepare derivative works or             *
phluido_l1  | *     improvements to Phluido Software;                                                               *
phluido_l1  | *   - rent, lease, lend, sell, sublicense, assign, distribute, publish, transfer or otherwise         *
phluido_l1  | *     make available the PHLUIDO Solution or any portion thereof to any third party;                  *
phluido_l1  | *   - reverse engineer, disassemble and/or decompile Phluido Software.                                *
phluido_l1  | *                                                                                                     *
phluido_l1  | *  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,           *
phluido_l1  | *  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A         *
phluido_l1  | *  PARTICULAR PURPOSE ARE DISCLAIMED.                                                                 *
phluido_l1  | *  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,              *
phluido_l1  | *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF                 *
phluido_l1  | *  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)             *
phluido_l1  | *  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR           *
phluido_l1  | *  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS                 *
phluido_l1  | *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                                       *
phluido_l1  | *                                                                                                     *
phluido_l1  | *******************************************************************************************************
phluido_l1  |
phluido_l1  | Copyright information already accepted on 2020-11-27, 08:56:08.
phluido_l1  | Starting Phluido 5G-NR L1 software...
phluido_l1  | 	PHAPI version       = 0.5 (12/10/2020)
phluido_l1  | 	L1 SW version       = 0.8.1
phluido_l1  | 	L1 SW internal rev  = r3852
phluido_l1  | Parsed configuration parameters:
phluido_l1  |     LicenseKey = XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX
phluido_l1  |     maxNumPrachDetectionSymbols = 1
phluido_l1  |     maxNumPdschLayers = 2
phluido_l1  |     maxNumPuschLayers = 1
phluido_l1  |     maxPuschModOrder = 6
phluido_l1  |
```

Perform these steps to get a running active cell.
* When the RU is still sending traffic use  ```ssh root@10.10.0.100 handshake``` to stop this traffic. 
* Start L1 and DU (run docker-compose up inside the install directory ).
* Use wireshark to follow the CPlane traffic, at this point following sequence:
```
     DU                                        CU
      |  F1SetupRequest--->                     |
      |                    <---F1SetupResponse  |
      |			                        |
      |	          <---GNBCUConfigurationUpdate  |
      |                                         |
```
   > The L1 starts listening on ip:port 10.10.0.1:44000

* After less than 30 seconds communication between rru and du starts. The related fiber port will report around 100 Mbytes/second of traffic in both directions
 
```
     DU                                        CU
      |  GNBCUConfigurationUpdateAck--->        |
      |                                         |
```

> NOTE : type ```ssh root@10.10.0.100 handshake``` again to stop the traffic. Make sure you stop the handshake explicitly at the end of your session else, even when stopping the DU/L1 manually, the RRU will keep the link alive and the next docker-compose up will find a cell busy transmitting on the fiber and the synchronization will not happen



## Starting RU Benetel 650 - cell wrapper way

### Install cell wrapper
#### On the HOST
To make the CU VM have access to the DU host ( bare metal server ) some privileges need to be given.

``` bash
printf "$USER ALL=(ALL) NOPASSWD:ALL\n" | sudo tee /etc/sudoers.d/$USER
sudo usermod -aG sudo $USER
```

#### On the CU VM
Go to the VM. In the VM a cell wrapper will get installed that controls the DU and RU ( cell ).
Going inside the CU VM.
``` 
ssh $USER@$NODE_IP 
```
Add some prerequisites if it is necessary

``` bash
sudo apt update 
sudo apt install zip
```

Create a public/private key pair and add it to kubernetes

``` bash
ssh-keygen -t ed25519 -f id_ed25519 -C cell-wrapper
```
``` bash
kubectl create secret generic cw-private --from-file=private=id_ed25519
```
``` bash
kubectl create secret generic cw-public --from-file=public=id_ed25519.pub
```

and copy the public key to the bare metal server ( DU host )
```
ssh-copy-id -i id_ed25519.pub ad@$SERVER_IP
```


Create a .yaml file containing the configuration. Also fill in the values you have prepared on the first page of the install guide.

It will install the cell-wrapper the will take care of the cell's health. 
In this configuration the cell-wrapper will reboot the RU every night at 2:00 AM. ```<reboot>true</reboot>``` 



``` xml
mkdir -p ~/install_$INSTALL_VERSION/ 
cd !$
tee cw.yaml <<EOF 
global:

  instanceId: "cw"
  natsUrl: "$NODE_IP"
  natsPort: "31100"

  redisHostname: "$NODE_IP"
  redisPort: "32220"

redis:
  backup:
    enabled: true
    deleteAfterDay: 7
  jobs:
    deleteExistingData: true

nats:
  enabled: false

#jobs:
#  - name: reboot-ru-1
#    schedule: "0 2 * * *"
#    rpc: |
#      <cell-wrapper xmlns="http://accelleran.com/ns/yang/accelleran-granny" #xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0" xc:operation="replace">
#        <radio-unit xc:operation="replace">
#          <name>vi su-1</name>
#          <reboot>true</reboot>
#        </radio-unit>
#      </cell-wrapper>

netconf:
  netconfService:
    nodePort: 31832

  configOnBoot:
    enabled: true
    deleteExistingConfig: true
    host: 'localhost'
    config: |
            <cell-wrapper xmlns="http://accelleran.com/ns/yang/accelleran-granny" xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0" xc:operation="create">
                <admin-state>unlocked</admin-state>

                <ssh-key-pair xc:operation="create">
                    <public-key>/home/accelleran/5G/ssh/public</public-key>
                    <private-key>/home/accelleran/5G/ssh/private</private-key>
                </ssh-key-pair>

                <auto-repair xc:operation="create">
                    <enable>true</enable>

                    <health-check xc:operation="create">
                        <rate xc:operation="create">
                            <seconds>5</seconds>
                            <milli-seconds>0</milli-seconds>
                        </rate>
                        <unacknowledged-counter-threshold>3</unacknowledged-counter-threshold>
                    </health-check>

                    <container-not-running-counter-threshold>2</container-not-running-counter-threshold>
                    <l1-not-listening-to-ru-counter-threshold>6</l1-not-listening-to-ru-counter-threshold>
                    <l1-rru-traffic-counter-threshold>6</l1-rru-traffic-counter-threshold>
                </auto-repair>

                <distributed-unit xc:operation="create">
                    <name>du-1</name>
                    <type>effnet</type>

                    <connection-details xc:operation="create">
                        <host>$SERVER_IP</host>
                        <port>22</port>
                        <username>$USER</username>
                    </connection-details>

                    <ssh-timeout>30</ssh-timeout>

                    <config xc:operation="create">
                        <cgi-plmn-id>$PLMN_ID</cgi-plmn-id>
                        <cgi-cell-id>000000000000000000000000000000000001</cgi-cell-id>
                        <pci>$PCI_ID</pci>
                        <tac>000001</tac>
                        <arfcn>$ARFCN_POINT_A</arfcn>
                        <frequency-band>$FREQ_BAND</frequency-band>
                        <plmns-id>$PLMN_ID</plmns-id>
                        <plmns-sst>1</plmns-sst>

                        <l1-license-key>$L1_PHLUIDO_KEY</l1-license-key>
                        <l1-bbu-addr>10.10.0.1</l1-bbu-addr>
                        <l1-max-pusch-mod-order>6</l1-max-pusch-mod-order>
                        <l1-max-num-pdsch-layers>2</l1-max-num-pdsch-layers>
                        <l1-max-num-pusch-layers>1</l1-max-num-pusch-layers>
                        <l1-num-workers>8</l1-num-workers>
                        <l1-target-recv-delay-us>2500</l1-target-recv-delay-us>
                        <l1-pucch-format0-threshold>0.01</l1-pucch-format0-threshold>
                        <l1-timing-offset-threshold-nsec>10000</l1-timing-offset-threshold-nsec>
                    </config>

                    <enable-auto-repair>true</enable-auto-repair>

                    <working-directory>/run</working-directory>
                    <storage-directory>/var/log</storage-directory>
                    <pcscd-socket>/run/pcscd/pcscd.comm</pcscd-socket>

                    <enable-log-saving>false</enable-log-saving>
                    <max-storage-disk-usage>80%</max-storage-disk-usage>

                    <enable-log-rotation>false</enable-log-rotation>
                    <log-rotation-pattern>*.0</log-rotation-pattern>
                    <log-rotation-count>1</log-rotation-count>

                    <centralized-unit-host>$F1_CU_IP</centralized-unit-host>
                    <l1-listening-port>44000</l1-listening-port>

                    <traffic-threshold xc:operation="create">
                        <uplink>10000</uplink>
                        <downlink>10000</downlink>
                    </traffic-threshold>

                    <du-image-tag>$DU_VERSION</du-image-tag>
                    <l1-image-tag>$L1_VERSION</l1-image-tag>

                    <du-extra-args>--cpuset-cpus=$CORE_SET_DU</du-extra-args>
                    <l1-extra-args>--cpuset-cpus=$CORE_SET_DU</l1-extra-args>


                    <du-base-config-file>/home/accelleran/5G/config/duEffnetConfig.json</du-base-config-file>

                    <radio-unit xc:operation="create">ru-1</radio-unit>
                </distributed-unit>

                <radio-unit xc:operation="create">
                    <name>ru-1</name>
                    <type>benetel650</type>

                    <connection-details xc:operation="create">
                        <host>10.10.0.100</host>
                        <port>22</port>
                        <username>root</username>
                    </connection-details>

                    <enable-ssh>false</enable-ssh>
                    <ssh-timeout>30</ssh-timeout>
                </radio-unit>
            </cell-wrapper>

EOF
```

> NOTE : uncomment the ```jobs:``` part if the RU should restart every night at 2am.

Install using helm.
```
helm repo update
helm install cw acc-helm/cw-cell-wrapper --values cw.yaml
```

Now you can see the kubernetes pods being created. Follow there progress with.

``` bash
watch -d kubectl get pod

```


### scripts to steer cell and cell-wrapper
Following script are delivered. They are located in the ```install_$CU_VERSION/accelleran/bin``` directory.
The $PATH variable is set accordingly.

  * ```cw-verify.sh```         - verifies if the cw.yaml file is parsed correctly after installation
  * ```cw-enable.sh```         - will enable the cell-wrapper.
  * ```cell-start.sh```       
  * ```cell-stop.sh```
  * ```cell-restart.sh```      
  * ```cw-disable.sh```        - cell-wrapper will not restar the cell when it is defect.
  * ```cw-debug-on.sh```       - turns on more logging
  * ```cw-debug-off.sh```      - turns on normal logging

The script do what there name says


## verify good operation of the B650 (all releases)

#### GPS
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

#### Cell Status Report

Verify if the boot sequence ended up correctly, by checking the radio status, the ouput shall mention explicitly the up time and the succesful bringup
```

> NOTE : this file is not present the first minute after reboot.

root@benetelru:~# cat /tmp/radio_status 
[INFO] Platform: RAN650_B
[INFO] Radio bringup begin
[INFO] Load EEPROM Data
[INFO] Tx1 Attenuation set to 15000 mdB
[INFO] Tx3 Attenuation set to 15730 mdB
[INFO] Operating Frequency set to 3774.720 MHz
[INFO] Waiting for Sync
[INFO] Sync completed
[INFO] Start Radio Configuration
[INFO] Initialize RF IC
[INFO] Disabled CFR for Antenna 1
[INFO] Disabled CFR for Antenna 3
[INFO] Move platform to TDD mode
[INFO] Set CP60 as TDD control master
[INFO] Enable TX on FEM
[INFO] FEM to full MIMO1_3 mode
[INFO] DPD Tx1 configuration
[INFO] DPD Tx3 configuration
[INFO] Set attn at 3774.720 MHz
[INFO] Reg 0xC0366 to 0x3FF
[INFO] Tuning the UE TA to reduce timing_offset
[INFO] The O-RU is ready for System Integration
[INFO] Radio bringup complete
 15:54:47 up 4 min,  load average: 0.09, 0.19, 0.08
 ```

### RU Status Report
some important registers must be checked to determine if the boot sequence has completed correctly:

```bash
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


Handshake messages are sent by the RU every second. When phluido L1 is starting or running it will Listen on port 44000 and reply to these messages.

Login to the server and check if the handshakes are happening: these are short messages sent periodically from the B650 to the server DU MAC address that was set as discussed and can be seen with a simple tcp dump command on the fiber interface of your server (enp45s0f0 for this example):

```
tcpdump -i enp45s0f0 -c 5 port 44000 -en
19:22:47.096453 02:00:5e:01:01:01 > 6c:b3:11:08:a4:e0, ethertype IPv4 (0x0800), length 64: 10.10.0.2.44000 > 10.10.0.1.44000: UDP, length 20
```

The above shows that 10.10.0.2 (U plane default IP address of the B650 Cell)  is sending a Handshake message from the MAC address 02:00:5e:01:01:01 (default MAC address of the B650 Uplane interface) to 10.10.0.1 (Server Fiber interface IP address) on MAC 6c:b3:11:08:a4:e0 (the MAC address of that fiber interface)

Such initial message may repeat a certain number of times, this is normal.



### Trace traffic between RU and L1.

As said, the first packet goes out from the Radio End to the DU, this is the handshake packet. The second packet is the Handshake response of the DU and we have to make sure that as described the MAC address used in such response from the DU has been set correctly so that the DATA Interface MAC address of the Radio End is used (by default in the Benetel Radio this MAC address is ```02:00:5e:01:01:01```) When data flows the udp packet lengths are 3874. 
Remember we increased the MTU size to 9000. Without increasing the L1 would crash on the fragmented udp packets.

```
$ tcpdump -i enp45s0f0 -c 20 port 44000 -en
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp45s0f0, link-type EN10MB (Ethernet), capture size 262144 bytes
19:22:47.096453 02:00:5e:01:01:01 > 6c:b3:11:08:a4:e0, ethertype IPv4 (0x0800), length 64: 10.10.0.2.44000 > 10.10.0.1.44000: UDP, length 20
19:22:47.106677 6c:b3:11:08:a4:e0 > 02:00:5e:01:01:01, ethertype IPv4 (0x0800), length 54: 10.10.0.1.44000 > 10.10.0.2.44000: UDP, length 12
19:23:14.596247 02:00:5e:01:01:01 > 6c:b3:11:08:a4:e0, ethertype IPv4 (0x0800), length 64: 10.10.0.2.44000 > 10.10.0.1.44000: UDP, length 12
19:23:14.596621 6c:b3:11:08:a4:e0 > 02:00:5e:01:01:01, ethertype IPv4 (0x0800), length 3874: 10.10.0.1.44000 > 10.10.0.2.44000: UDP, length 3832
19:23:14.596631 6c:b3:11:08:a4:e0 > 02:00:5e:01:01:01, ethertype IPv4 (0x0800), length 3874: 10.10.0.1.44000 > 10.10.0.2.44000: UDP, length 3832

```

### Cell is ON
#### Check if the L1 is listening 
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

#### Show the traffic between rru and l1

```
$ ifstat -i enp45s0f0
    enp45s0f0     
 KB/s in  KB/s out
71320.01  105959.7
71313.36  105930.1
```

## Troubleshooting
### DEBUG Configuration
  * To enable the L1 and DU logs to get saved after a cellwrapper intervention, install the cellwrapper with these settings.
```
<enable-log-saving>true</enable-log-saving>
```

### Fiber Port not showing up
https://www.serveradminz.com/blog/unsupported-sfp-linux/

### L1 is not listening
Check if L1 is listening on port 44000 by typing

```
$ netstat -ano | grep 44000
```

If nothing is shown L1 is not listening. In this case do a trace on the F1 port like this.

```
tcpdump -i any port 38472
18:26:30.940491 IP 10.244.0.208.38472 > bare-metal-node-cab-3.59910: sctp (1) [HB REQ] 
18:26:30.940491 IP 10.244.0.208.38472 > bare-metal-node-cab-3.maas.56153: sctp (1) [HB REQ] 
18:26:30.940530 IP bare-metal-node-cab-3.59910 > 10.244.0.208.38472: sctp (1) [HB ACK] 
18:26:30.940532 IP bare-metal-node-cab-3.59910 > 10.244.0.208.38472: sctp (1) [HB ACK] 
```
you should see the HB REQ and ACK messages. If not Check 
 * the docker-compose.yml file if the cu ip address matches the following bullet
 * check ```kubectl get services ``` if the F1 service is running with the that maches previous bullet 


### check SCTP connections
There are 3 UDP ports you can check. When the system starts up it will setup 3 SCTP connections on following ports in the order mentioned here :

* 38462 - E1 SCTP connection - SCTP between DU and CU
* 38472 - F1 SCTP connection - SCTP between CU UP and CU CP
* 38412 - NGAP SCTP connection - SCTP between CU CP and CORE

