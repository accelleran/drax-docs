# DU Installation 

## Introduction
The DU will be installed in several Docker containers that run on the host machine.

**Before proceding further make sure Docker and docker-compose have been installed and that docker can be run without superuser privileges, this is a prerequisite.**

See, if you didn't do it already, [the chapter on Kubernetes Installation](../kubernetes-install/index.md) for information on how to do this.

### Diagram
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

### Variables needed for this install
Before proceeding you may want to crosscheck and modify some paramters that caracterise each deployment and depends on the desired provisioning of the components. The parameters that should be considered for this purpose and can be safely modified are:

* How long needs the RU 48V powercable need to be ? 
* license key delivered by phluido ( eg 2B2A-962F-783F-40B9-7064-2DE3-3906-9D2E )

* plmn_identity      ( eg 235 88 )
* nr_cell_identity   ( eg 1  any number )
* nr_pci             ( eg 1  not any number. Ask Accelleran to do the PCI planning) 
* 5gs_tac            ( eg 1 ) 

* center_frequency_band   ( eg  3751.680 )
* point_a_arfcn           ( 648840 consistent with center freq ) 
* band               	  ( 77  consistent with center frequency )     
* scs                     ( 30khz ) 

For any other modification it is advisable to make contact with the Accelleran service desk as of course, if in principle every paramter in the confuguration file is up for modification, it is certainly not recommendable to proceed in that declaration as each front end may or may not work as a consequence and the analysis and recovery from error scenario will be less than intuitive


## Install a Low Latency Kernel

The PHY layer has very stringent latency requirements, therefore we install a low latency kernel:

``` bash
sudo apt install linux-image-lowlatency
```

Create a sysctl configuration file to configure the low latency kernel:

``` bash
sudo tee /etc/sysctl.d/10-phluido.conf <<EOF
# Improves scheduling responsiveness for Phluido L1
kernel.sched_min_granularity_ns = 100000
kernel.sched_wakeup_granularity_ns = 20000
kernel.sched_latency_ns = 500000
kernel.sched_rt_runtime_us = -1
# Message queue
fs.mqueue.msg_max = 64
EOF
```

Remove the generic kernel to avoid the low latency kernel to be replaced by a generic kernel when updates are performed:

``` bash
sudo apt remove linux-image-generic
sudo apt autoremove
```

In order to avoid possible system performance degradation, CPU scaling must be disabled:

``` bash
sudo apt install cpufrequtils
```
```
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
```
```
sudo systemctl disable ondemand
```

Restart the machine to make the changes take effect:

``` bash
sudo reboot
```

## Obtain the Effnet and Phluido licenses

### Preparation steps
In this phase we will need to act in parallel for the DU and the L1/RRU licenses, which depend on our partner company so it is essential to give priority and possibly anticipate these two steps as there is no specific effort involved from the user/customer perspective and they may require longer than one working day before we can proceed further.

Verify the following archive files have been delivered and are available to you before taking further actions:

1. accelleran-du-phluido-xxxx.zip
2. Phluido5GL1_vx.x.x.zip   ( or a .tar file )
3. effnet-license-activation-yyyy_mm_dd.zip 

**Note** For the license activation file we indicate the generic format yyyy_mm_dd as the file name may vary from case to case, your Accelleran point of contact will make sure you receive the correct license activation archive file which will have a certain timestamp on it, example effnet-license-activation-2021-12-16.zip

**Note:** if you don't have yet the effnet license activation bundle, in order to obatin one you must comunicate to Accelleran the serial number of the Yubikey you intend to use so to be enabled for usage. You can obtain this information by using the following command on your server where the Yubikey has been installed physically to a USB port:

To check if the server can see the key do (in this example Device004 is your key): 
``` bash
lsusb
~$ lsusb
Bus 002 Device 002: ID 8087:8002 Intel Corp. 
Bus 002 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 001 Device 002: ID 8087:800a Intel Corp. 
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 004 Device 003: ID 2500:0020 Ettus Research LLC USRP B200
Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
**Bus 003 Device 004: ID 1050:0407 Yubico.com Yubikey 4 OTP+U2F+CCID**
Bus 003 Device 029: ID 2a70:9024 OnePlus AC2003
Bus 003 Device 006: ID 413c:a001 Dell Computer Corp. Hub
Bus 003 Device 016: ID 20ce:0023 Minicircuits Mini-Circuits
Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub

```

Then you can find the serial number (yubikey-manager needed, install if it's not already):

``` bash
sudo apt install yubikey-manager
ykman list --serials
13134288
```

Once you have the three archive files mentioned above create the directories to store the Effnet and Phluido software:

``` bash
mkdir -p accelleran-du-phluido Phluido5GL1/Phluido5GL1_v0.8.1
```

Place `accelleran-du-phluido-2022-01-31.zip` in `accelleran-du-phluido` and unzip it:

``` bash
unzip accelleran-du-phluido/accelleran-du-phluido-2022-01-31.zip -d accelleran-du-phluido
```

Place `Phluido5GL1_v0.8.1.zip` in `Phluido5GL1` and unzip it:

``` bash
unzip Phluido5GL1/Phluido5GL1_v0.8.1.zip -d Phluido5GL1/Phluido5GL1_v0.8.1
```

Create `Phluido5GL1/Phluido5GL1_v0.8.1/L1_NR_copyright`.
This file contains the date and time on which you agreed to the Phluido copyright notice and is required to build the Phluido L1 Docker image:

``` bash
date '+%Y-%m-%d, %H:%M:%S' >Phluido5GL1/Phluido5GL1_v0.8.1/L1_NR_copyright
```


### Effnet License: Create a PCSCD Docker Image 

The DU software needs access to a YubiKey that contains its license.
The license in the YubiKey is shared by the PCSCD daemon, which itself can run in a Docker container to satisfy OS dependencies.
Plug the YubiKey in a USB port of the machine.
Then, create a Dockerfile named Dockerfile.pcscd for this Docker image:

``` bash
mkdir -p pcscd
tee pcscd/Dockerfile.pcscd <<EOF
FROM ubuntu:20.04

RUN \
set -xe && \
apt-get update && \
DEBIAN_FRONTEND="noninteractive" apt-get install -y \
    pcscd

# Cleanup
RUN \
set -xe && \
apt-get clean && \
rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

ENTRYPOINT ["/usr/sbin/pcscd", "--foreground"]
EOF
```

The Docker image can now be built and started with:

``` bash
docker build --rm -t pcscd_yubikey - <pcscd/Dockerfile.pcscd
```
```
docker run --restart always -id --privileged --name pcscd_yubikey_c -v /run/pcscd:/run/pcscd pcscd_yubikey
```

You can verify it is running correct with the command:

``` bash
docker container ls --filter name=pcscd_yubikey_c
```

If every step was performed correctly this command should produce output similar to:

``` bash
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
df4f41eb70c9        pcscd_yubikey       "/usr/sbin/pcscd --f…"   1 minute ago        Up 1 minute                             pcscd_yubikey_c
```

### Effnet License: activate the yubikey 

In order to activate the license dongles unzip the received license activation bundle effnet-license-activation-yyyy-mm-dd.zip (as mentioned the date may differ on each case so let's use the generic format) and then you need to load the included Docker image into your docker-daemon, i.e.

``` bash
bunzip2 --stdout license-activation-yyyy-mm-dd.tar.bz2 | docker load
```

Then run the image mapping the folder containing the `pcscd` daemon socket into
the container:

``` bash
docker run -it -v /var/run/pcscd:/var/run/pcscd effnet/license-activation-yyyy-mm-dd
```

If you get warnings similar to:

``` bash
WARNING: No dongle with serial-number 13134288 found
```

It means that a dongle for the bundled license was not found, i.e. in this case
the dongle with the serial number 13134288 has not been activated, or the licens bundle file you have received is not the correct one, contact Accelleran in such case

Successful activation of a license-dongle should produce an output similar to:

``` bash
Loading certificate to Yubico YubiKey CCID 00 00 (serial: 13134288)
```

Which means that a license for the dongle with serial-number 13134288 was loaded to the dongle (i.e., it was bundled in the license-activation image).


## Install the Phluido and Effnet Docker Images


Load the Effnet DU Docker image:

``` bash
bzcat accelleran-du-phluido/accelleran-du-phluido-2022-01-31/gnb_du_main_phluido-2022-01-31.tar.bz2 | docker image load
```

Load the Phluido L1 Docker image:

``` bash
docker build -f accelleran-du-phluido/accelleran-du-phluido-2022-01-31/phluido/docker/Dockerfile.l1 -t phluido_l1:v0.8.1 Phluido5GL1/Phluido5GL1_v0.8.1
```

or in case the delivered file is a .tar file

```
docker image load phluido_docker_0842.tar
```

**FOR B210 RU ONLY** : Load the Phluido RRU Docker image (this step does not have to be taken when using Benetel RUs):

``` bash
docker build -f accelleran-du-phluido/accelleran-du-phluido-2022-01-31/phluido/docker/Dockerfile.rru -t phluido_rru:v0.8.1 Phluido5GL1/Phluido5GL1_v0.8.1
```




## Prepare and bring on air the USRP B210 Radio

This section is exclusively applicable to the user/customer that intends to use the Ettus USRP B210 Radio End with our Accellleran 5G end to end solution, if you do not have such radio end the informations included in this section may be misleading and bring to undefined error scenarios. Please contact Accelleran if your Radio End is not included in any section of this user guide

Create the UDEV rules for the B210:

``` bash
sudo tee /etc/udev/rules.d/uhd-usrp.rules <<EOF
#
# Copyright 2011,2015 Ettus Research LLC
# Copyright 2018 Ettus Research, a National Instruments Company
#
# SPDX-License-Identifier: GPL-3.0-or-later
#

#USRP1
SUBSYSTEMS=="usb", ATTRS{idVendor}=="fffe", ATTRS{idProduct}=="0002", MODE:="0666"

#B100
SUBSYSTEMS=="usb", ATTRS{idVendor}=="2500", ATTRS{idProduct}=="0002", MODE:="0666"

#B200
SUBSYSTEMS=="usb", ATTRS{idVendor}=="2500", ATTRS{idProduct}=="0020", MODE:="0666"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="2500", ATTRS{idProduct}=="0021", MODE:="0666"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="2500", ATTRS{idProduct}=="0022", MODE:="0666"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="3923", ATTRS{idProduct}=="7813", MODE:="0666"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="3923", ATTRS{idProduct}=="7814", MODE:="0666"
EOF
```

Connect the B210 to the machine.
Make sure it is enumerated as USB3 by executing:

``` bash
lsusb -d 2500:0020 -v | grep -F bcdUSB
```

This should print:

```
bcdUSB               3.00
```

Add the Ettus Research APT repositories:

``` bash
sudo add-apt-repository ppa:ettusresearch/uhd
sudo apt update
```

Install the software required by the B210:

``` bash
sudo apt install libuhd-dev uhd-host libuhd3.15.0
```

Download the UHD images:

``` bash
sudo uhd_images_downloader
```

Check if the B210 is detecting using the following command:

``` bash
uhd_find_devices
```

This should output something similar to:

```
[INFO] [UHD] linux; GNU C++ version 7.5.0; Boost_106501; UHD_3.15.0.0-release
--------------------------------------------------
-- UHD Device 0
--------------------------------------------------
Device Address:
    serial: 3218C86
    name: MyB210
    product: B210
    type: b200
```

Burn the correct EEPROM for the B210:

``` bash
/usr/lib/uhd/utils/usrp_burn_mb_eeprom* --values='name=B210-#4'
```

If everything goes well this should output something similar to:

```
Creating USRP device from address:
[INFO] [UHD] linux; GNU C++ version 7.5.0; Boost_106501; UHD_3.15.0.0-release
[INFO] [B200] Detected Device: B210
[INFO] [B200] Loading FPGA image: /usr/share/uhd/images/usrp_b210_fpga.bin...
[INFO] [B200] Operating over USB 3.
[INFO] [B200] Detecting internal GPSDO....
[INFO] [GPS] No GPSDO found
[INFO] [B200] Initialize CODEC control...
[INFO] [B200] Initialize Radio control...
[INFO] [B200] Performing register loopback test...
[INFO] [B200] Register loopback test passed
[INFO] [B200] Performing register loopback test...
[INFO] [B200] Register loopback test passed
[INFO] [B200] Setting master clock rate selection to 'automatic'.
[INFO] [B200] Asking for clock rate 16.000000 MHz...
[INFO] [B200] Actually got clock rate 16.000000 MHz.

Fetching current settings from EEPROM...
    EEPROM ["name"] is "MyB210"

Setting EEPROM ["name"] to "B210-#4"...
Power-cycle the USRP device for the changes to take effect.

Done
```

Check if the current EEPROM was flashed by executing:

``` bash
uhd_find_devices
```

The output should look like:

```
[INFO] [UHD] linux; GNU C++ version 7.5.0; Boost_106501; UHD_3.15.0.0-release
--------------------------------------------------
-- UHD Device 0
--------------------------------------------------
Device Address:
    serial: 3218C86
    name: B210-#4
    product: B210
    type: b200
```
### DU/L1/RRU Configuration and docker compose

Before starting the configuration of the components it is important to avoid confusion so please create a folder file and move in all the configuration files you find for the L1, RRU and the DU configuration and remove the docker-compose as well:
``` bash
mkdir accelleran-du-phluido/accelleran-du-phluido-2022-01-31/phluido/cfg
mv accelleran-du-phluido/accelleran-du-phluido-2022-01-31/phluido/*.cfg accelleran-du-phluido/accelleran-du-phluido-2022-01-31/phluido/cfg/
mkdir accelleran-du-phluido/accelleran-du-phluido-2022-01-31/json
mv accelleran-du-phluido/accelleran-du-phluido-2022-01-31/*.json accelleran-du-phluido/accelleran-du-phluido-2022-01-31/json/
rm accelleran-du-phluido/accelleran-du-phluido-2022-01-31/docker-compose.yml
```

Create a configuration file for the Phluido RRU:

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2022-01-31/phluido/PhluidoRRU_NR_EffnetTDD_B210.cfg <<EOF
/******************************************************************
*
* This file is subject to the terms and conditions defined in
* file 'LICENSE.txt', which is part of this source code package.
*
******************************************************************/

//BBU IPv4 address.
bbuFronthaulServerAddr = "127.0.0.1";

// Number of slots in one subframe.
numSubframeSlots = 2;

//Number of TX antennas for fronthaul data exchange.
numTxAntennas = 1;
//Number of RX antennas for fronthaul data exchange.
numRxAntennas = 1;

/// Frequency [kHz] for TX "point A" (see NR definition).
txFreqPointA_kHz = 3301680;
/// Frequency [kHz] for RX "point A" (see NR definition).
rxFreqPointA_kHz = 3301680;

/// Number of PRBs for both downlink and uplink. Must match the L2-L3 configuration.
numPrbs = 51;

uhdClockMode = 0;

uhdSendAdvance_ns = 8000;

/// Parameters used for PhluidoPrototypeBPP.
bppMode = 10;
uhdSamplingRate_kHz = 23040;
EOF
```

Create a configuration file for the Phluido L1.
Make sure to set the value `LicenseKey` option to the received Phluido license key. This key has been delivered by Phluido upon receipt of the .bin file generated by the sysTest you have performed at start of this installation.

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2022-01-31/phluido/PhluidoL1_NR_B210.cfg <<EOF
/******************************************************************
*
* This file is subject to the terms and conditions defined in
* file 'LICENSE'.
*
******************************************************************/

//Enables verbose binary logging. WARNING: very CPU intensive and creates potentially huge output files. Use with caution.
//logLevel_verbose    = "DEBUG";

//Enable 64-QAM support for PUSCH (license-specific)
//maxPuschModOrder = 6;

//Enable radio unit emulation mode and define corresponding number of (emulated) antennas
//backEndMode = 0;
//numEmulTxAntennas = 2;
//numEmulRxAntennas = 1;

//Enable 64-QAM support for PUSCH (license-specific)
maxPuschModOrder = 6;

maxNumPdschLayers = 2;
maxNumPuschLayers = 1;
maxNumPrachDetectionSymbols = 1;

//License key put here please the effective 32 digits sequence you received for this deployment
LicenseKey = "XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX";
EOF
```
**IMPORTANT: After this replace the LicenseKey value with the effective license sequence you obtained from Accelleran 


Create a configuration file for the Effnet DU:

* nr_cell_identity  ( in binary format eg 3 fill in ...00011 )
* nr_pci            ( decimal format eg 51 fill in 51 )
* plmn_identity     ( eg 235 88 fill in 235f88. fill in 2 times in this file)
* arfcn             ( decimal format calculated from the center frequency  ) 
* nr_frequency_band ( 77 or 78 )
* 5gs_tac           ( 3 byte array. eg 1 fill in 000001 ) 

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2022-01-31/b210_config_20mhz.json <<EOF
{
    "configuration": {
        "du_address": "du",
        "cu_address": "cu",
        "gtp_listen_address": "du",
        "vphy_listen_address": "127.0.0.1",
        "vphy_port": 13337,
        "vphy_tick_multiplier": 1,
        "gnb_du_id": 38209903575,
        "gnb_du_name": "The quick brown fox jumps over a lazy dog",
        "phy_control": {
            "crnti_range": {
                "min": 42000,
                "max": 42049
            }
        },
        "rrc_version": {
            "x": 15,
            "y": 6,
            "z": 0
        },
        "served_cells_list": [
            {
                "served_cell_information": {
                    "nr_cgi": {
                        "plmn_identity": "001f01",
                        "nr_cell_identity": "000000000000000000000000000000000001"
                    },
                    "nr_pci": 42,
                    "5gs_tac": "000001",
                    "ran_area_code": 1,
                    "served_plmns": [
                        {
                            "plmn_identity": "001f01",
                            "tai_slice_support_list": [
                                {
                                    "sst": 1
                                }
                            ]
                        }
                    ],
                    "nr_mode_info": {
                        "nr_freq_info": {
                            "nr_arfcn": 620112,
                            "frequency_band_list": [
                                {
                                    "nr_frequency_band": 78
                                }
                            ]
                        },
                        "transmission_bandwidth": {
                            "bandwidth_mhz": 20,
                            "scs_khz": 30,
                            "nrb": 51
                        },
                        "pattern": {
                            "periodicity_in_slots": 5,
                            "downlink": {
                                "slots": 3,
                                "symbols": 7
                            },
                            "uplink": {
                                "slots": 1,
                                "symbols": 4
                            }
                        }
                    },
                    "measurement_timing_configuration": [
                        222,
                        173,
                        190,
                        239
                    ],
                    "dmrs_type_a_position": "pos3",
                    "intra_freq_reselection": "allowed",
                    "ssb_pattern": "1000000000000000000000000000000000000000000000000000000000000000",
                    "ssb_periodicity_serving_cell_ms": 20,
                    "prach_configuration_index": 202,
                    "ssb_pbch_scs": 30,
                    "offset_point_a": 0,
                    "k_ssb": 0,
                    "coreset_zero_index": 5,
                    "search_space_zero_index": 2,
                    "ra_response_window_slots": 20,
                    "sr_slot_periodicity": 40,
                    "sr_slot_offset": 3,
                    "search_space_other_si": 1,
                    "paging_search_space": 1,
                    "ra_search_space": 1,
                    "bwps": [
                        {
                            "id": 0,
                            "start_crb": 0,
                            "num_rb": 51,
                            "scs": 30,
                            "cyclic_prefix": "normal"
                        }
                    ],
                    "coresets": [
                        {
                            "id": 1,
                            "bwp_id": 0,
                            "fd_resources": "111100000000000000000000000000000000000000000",
                            "duration": 3,
                            "interleaved": {
                                "reg_bundle_size": 6,
                                "interleaver_size": 2
                            },
                            "precoder_granularity": "same_as_reg_bundle"
                        }
                    ],
                    "search_spaces": [
                        {
                            "id": 1,
                            "control_resource_set_id": 0,
                            "common": {}
                        },
                        {
                            "id": 2,
                            "control_resource_set_id": 1,
                            "ue_specific": {
                                "dci_formats": "formats0-1-And-1-1"
                            }
                        }
                    ],
                    "num_tx_antennas": 1,
                    "trs": {
                        "periodicity_and_offset": {
                            "period": 80,
                            "offset": 1
                        },
                        "symbol_pair": "four_eight",
                        "subcarrier_location": 1
                    },
                    "csi_rs": {
                        "periodicity_and_offset": {
                            "period": 40,
                            "offset": 15
                        }
                    },
                    "force_dl_mimo_layers": 1,
                    "harq_processes_for_pdsch": 16,
                    "minimum_k1_delay": 1,
                    "minimum_k2_delay": 3,
                    "force_rlc_buffer_size": 2500000
                }
            }
        ]
    }
}
EOF
```

Before creating the `docker-compose.yml` file, make sure to set the `$CU_IP` environment variable where you will store the F1 IP address of the CUCP that you have already deployed using the dRAX Dashboard (section [CUCP Installation](../drax-install/images/dashboard-cu-cp-deployment.png) )
This IP address can be determined by executing the following command:

``` bash
kubectl get services | grep f1
```
The CUCP F1 SCTP interface external address is the second IP address and should be in the IP pool that was assigned to MetalLB in [dRax Installation](../drax-install/index.md).

Now, create a docker-compose configuration file:

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2021-09-30/docker-compose.yml <<EOF
version: "3"

services:

  phluido_l1:
    image: phluido_l1:v0.8.4.2
    container_name: phluido_l1
    tty: true
    privileged: true
    ipc: shareable
    shm_size: 2gb
    command: /config.cfg
    volumes:
      - "$PWD/phluido/PhluidoL1_NR_B210.cfg:/config.cfg:ro"
      - "/run/logs-du/l1:/workdir"
      - "/etc/machine-id:/etc/machine-id:ro"
    working_dir: "/workdir"
    network_mode: host

  du:
    image: gnb_du_main_phluido:2022-07-01-q2-pre-release
    volumes:
      - "$PWD/b210_config_20mhz.json:/config.json:ro"
      - "/run/logs-du/du:/workdir"
      - /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm
    ipc: container:phluido_l1
    tty: true
    privileged: true
    depends_on:
      - phluido_l1
    entrypoint: ["/bin/sh", "-c", "sleep 4 && exec /gnb_du_main_phluido /config.json"]
    working_dir: "/workdir"
    extra_hosts:
      - "cu:$F1_CU_IP"
      - "du:$SERVER_IP"

  phluido_rru:
    image: phluido_rru:v0.8.4.2
    tty: true
    privileged: true
    depends_on:
      - du
      - phluido_l1
    network_mode: host
    volumes:
      - "$PWD/phluido/PhluidoRRU_NR_EffnetTDD_B210.cfg:/config.cfg:ro"
      - "$PWD/logs/rru:/workdir"
    entrypoint: ["/bin/sh", "-c", "sleep 20 && exec /PhluidoRRU_NR /config.cfg"]
    working_dir: "/workdir"
EOF
```

### Start the DU

Start the DU by running the following command:

``` bash
docker-compose up -f accelleran-du-phluido/accelleran-du-phluido-2022-01-31/docker-compose.yml
```

If all goes well this will produce output similar to:

```
Starting phluido_l1 ... done
Recreating accelleran-du-phluido-2022-01-31_du_1 ... done
Recreating accelleran-du-phluido-2022-01-31_phluido_rru_1 ... done
Attaching to phluido_l1, accelleran-du-phluido-2022-01-31_du_1, accelleran-du-phluido-2022-01-31_phluido_rru_1
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
phluido_rru_1  | linux; GNU C++ version 7.3.0; Boost_106501; UHD_003.010.003.000-0-unknown
phluido_rru_1  |
phluido_rru_1  | Logs will be written to file "phluidoRru.log".
phluido_rru_1  | -- Detected Device: B210
phluido_rru_1  | -- Operating over USB 3.
phluido_rru_1  | -- Initialize CODEC control...
phluido_rru_1  | -- Initialize Radio control...
phluido_rru_1  | -- Performing register loopback test... pass
phluido_rru_1  | -- Performing register loopback test... pass
phluido_rru_1  | -- Performing CODEC loopback test... pass
phluido_rru_1  | -- Performing CODEC loopback test... pass
phluido_rru_1  | -- Setting master clock rate selection to 'automatic'.
phluido_rru_1  | -- Asking for clock rate 16.000000 MHz...
phluido_rru_1  | -- Actually got clock rate 16.000000 MHz.
phluido_rru_1  | -- Performing timer loopback test... pass
phluido_rru_1  | -- Performing timer loopback test... pass
phluido_rru_1  | -- Setting master clock rate selection to 'manual'.
phluido_rru_1  | -- Asking for clock rate 23.040000 MHz...
phluido_rru_1  | -- Actually got clock rate 23.040000 MHz.
phluido_rru_1  | -- Performing timer loopback test... pass
phluido_rru_1  | -- Performing timer loopback test... pass
```

## Prepare and bring on air the Benetel 650 Radio

This section is exclusively applicable to the user/customer that intends to use the Benetel B650 Radio End with our Accellleran 5G end to end solution, if you do not have such radio end the informations included in this section may be misleading and bring to undefined error scenarios. Please contact Accelleran if your Radio End is not included in any section of this user guide




             
### DU/L1 Configuration and docker compose

Differently from the Ettus B210, Benetel runs the RRU software on board, therefore we only need to prepare 2 software components in the server, that is, 2 Containers, Effnet DU and Phluido L1.

Create the configuration file for the Phluido L1 component the `PhluidoL1_NR_Benetel.cfg` file delivered by effnet
Make sure to set the value `LicenseKey` option to the received Phluido license key:

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2022-01-31/phluido/PhluidoL1_NR_Benetel.cfg <<EOF
/******************************************************************
 *
 * This file is subject to the terms and conditions defined in
 * file 'LICENSE'.
 *
 ******************************************************************/
//Enables verbose binary logging. WARNING: very CPU intensive and creates potentially huge output files. Use with caution.
//
// DEVEL: 		1.2G/67 
// DEBUG: 		953M/67 
// INFORMATIVE:	29K/67 
// default: 	26K/67 
// CRITICAL: 	0/393 
// WARNING: 	0/393        (x/y x=log size in L1.encr.log file, y=log size in L1.open.log file. In a time of 1 minute )

//logLevel_verbose    = "WARNING";     
bbuFronthaulServerMode = 1;
bbuFronthaulServerAddr = "10.10.0.1";

// Enable 64-QAM support for PUSCH (license-specific).
maxPuschModOrder = 6;
maxNumPdschLayers = 2;
maxNumPuschLayers = 1;

targetRecvSymbolDelay = 70; // setting for old SW version
targetRecvSymbolDelay_us = 2500; //settings for new SW version

numWorkers = 6;
//License key put here please the effective 32 digits sequence you received for this deployment
LicenseKey = "XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX";
EOF

```
**IMPORTANT: After this replace the LicenseKey value with the effective license sequence you obtained from Accelleran, all the other parameters shall not be modified 


Create a configuration file for the Effnet DU:

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2022-01-31/b650_config_40mhz.json <<EOF
{
    "configuration": {
        "du_address": "du",
        "cu_address": "cu",
        "gtp_listen_address": "du",
        "vphy_listen_address": "127.0.0.1",
        "vphy_port": 13337,
        "vphy_tick_multiplier": 1,
        "gnb_du_id": 38209903575,
        "gnb_du_name": "This is the dell two HO setup cell one",
        "phy_control": {
            "crnti_range": {
                "min": 42000,
                "max": 42049
            }
        },
        "rrc_version": {
            "x": 15,
            "y": 6,
            "z": 0
        },
        "served_cells_list": [
            {
                "served_cell_information": {
                    "nr_cgi": {
                        "plmn_identity": "001f01",
                        "nr_cell_identity": "000000000000000000000000000000000001"
                    },
                    "nr_pci": 51,
                    "5gs_tac": "000001",
                    "ran_area_code": 1,
                    "served_plmns": [
                        {
                            "plmn_identity": "001f01",
                            "tai_slice_support_list": [
                                {
                                    "sst": 1
                                }
                            ]
                        }
                    ],
                    "nr_mode_info": {
                        "nr_freq_info": {
                            "nr_arfcn": 648840,
                            "frequency_band_list": [
                                {
                                    "nr_frequency_band": 78
                                }
                            ]
                        },
                        "transmission_bandwidth": {
                            "bandwidth_mhz": 40,
                            "scs_khz": 30,
                            "nrb": 106
                        },
                        "pattern": {
                            "periodicity_in_slots": 10,
                            "downlink": {
                                "slots": 7,
                                "symbols": 6
                            },
                            "uplink": {
                                "slots": 2,
                                "symbols": 4
                            }
                        }
                    },
                    "measurement_timing_configuration": [
                        222,
                        173,
                        190,
                        239
                    ],
                    "dmrs_type_a_position": "pos2",
                    "intra_freq_reselection": "allowed",
                    "ssb_pattern": "1000000000000000000000000000000000000000000000000000000000000000",
                    "ssb_periodicity_serving_cell_ms": 20,
                    "prach_configuration_index": 202,
                    "ssb_pbch_scs": 30,
                    "offset_point_a": 6,
                    "k_ssb": 0,
                    "coreset_zero_index": 3,
                    "search_space_zero_index": 2,
                    "ra_response_window_slots": 20,
                    "sr_slot_periodicity": 40,
                    "sr_slot_offset": 7,
                    "search_space_other_si": 1,
                    "paging_search_space": 1,
                    "ra_search_space": 1,
                    "bwps": [
                        {
                            "id": 0,
                            "start_crb": 0,
                            "num_rb": 106,
                            "scs": 30,
                            "cyclic_prefix": "normal"
                        }
                    ],
                    "coresets": [
                        {
                            "id": 1,
                            "bwp_id": 0,
                            "fd_resources": "111100000000000000000000000000000000000000000",
                            "duration": 2,
                            "interleaved": {
                                "reg_bundle_size": 6,
                                "interleaver_size": 2
                            },
                            "precoder_granularity": "same_as_reg_bundle"
                        }
                    ],
                    "search_spaces": [
                        {
                            "id": 1,
                            "control_resource_set_id": 0,
                            "common": {}
                        },
                        {
                            "id": 2,
                            "control_resource_set_id": 1,
                            "ue_specific": {
                                "dci_formats": "formats0-1-And-1-1"
                            }
                        }
                    ],
                    "maximum_ru_power_dbm": 23.0,
                    "num_tx_antennas": 2,
                    "trs": {
                        "periodicity_and_offset": {
                            "period": 80,
                            "offset": 1
                        },
                        "symbol_pair": "four_eight",
                        "subcarrier_location": 1
                    },
                    "periodic_srs_periodicity": 64,
                    "csi_rs": {
                        "periodicity_and_offset": {
                            "period": 40,
                            "offset": 15
                        }
                    },
                    "force_rlc_buffer_size": 2500000,
                    "harq_processes_for_pdsch": 16,
                    "minimum_k1_delay": 1,
                    "minimum_k2_delay": 1                
                }
            }
        ]
    }
}

EOF
```

### Frequency, Offsets, Point A Calculation
This section is essential to proceed correctly and determine the exact parameters that will allow the Benetel Radio to go on air correctly and the UEs to be able to see the cell and attempt an attach so it is particularly important to proceed carefully on this point. there are currently several limitations on the Frequencies that go beyond the simple definition of 5G NR Band:

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
  <img width="600" height="800" src="Freq3747dot84.png">
</p>
This Frequency, however does not meet the **GSCN Synchronisation requirements** as in fact the Offset to Point A of the first channel is 2 and the K_ssb is 16, this will cause the UE to listen on the wrong channel so the SIBs will never be seen and therefore the cell is "invisible"

- We then repeat the exercise with the higher center frequency 3751,68 MHz, which yelds a center frequency ARFCN of 650112 and a point A ARFCN of 648840 and giving another run we will see that now the K_ssb and the Offset to Point A are correct:
<p align="center">
  <img width="600" height="800" src="Freq3751dot68.png">
</p>
With these information at hand we are going to determine:

* point A frequency : 3732.60  ( arfcn : 648840 ) - edit du configuration in the appropriate json file
* center Frequency  : 3751.68  ( arfcn : 650112 ) - edit rru configuration directly on the Benetel Radio End (see next sections)

### Create docker compose

Before creating the `docker-compose.yml` file, make sure to set the `$CU_IP` environment variable where you will store the F1 IP address of the CUCP that you have already deployed using the dRAX Dashboard (section [CUCP Installation](../drax-install/images/dashboard-cu-cp-deployment.png) )
This IP address can be determined by executing the following command:

``` bash
kubectl get services | grep f1
```
The CUCP F1 SCTP interface external address is the second IP address and should be in the IP pool that was assigned to MetalLB in [dRax Installation](../drax-install/index.md).

Now, create a docker-compose configuration file:

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2022-01-31/docker-compose-B650.yml <<EOF
version: "3"

services:

  phluido_l1:
    image: phluido_l1
    container_name: phluido_l1
    tty: true
    privileged: true
    ipc: shareable
    shm_size: 2gb
    command: /config.cfg
    volumes:
      - "$PWD/phluido/PhluidoL1_NR_Benetel.cfg:/config.cfg:ro"
      - "$PWD/logs/l1:/workdir"
      - "/etc/machine-id:/etc/machine-id:ro"
    working_dir: "/workdir"
    network_mode: host

  du:
    image: gnb_du_main_phluido
    volumes:
      - "$PWD/b650_config_40mhz.json:/config.json:ro"
      - "$PWD/logs/du:/workdir"
      - /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm
    ipc: container:phluido_l1
    tty: true
    privileged: true
    depends_on:
      - phluido_l1
    entrypoint: ["/bin/sh", "-c", "sleep 4 && exec /gnb_du_main_phluido /config.json"]
    working_dir: "/workdir"
    extra_hosts:
      - "cu:$CU_IP"

EOF
```

### Prepare the server for the Benetel 650

The benetel is connected with a fiber to the server. 
1. The port on the physical B650 RRU is labeled ```port FIBER1```
2. The port on the server is one of these listed below.

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
In this example it's enp45s0f0. This port is the one we connected the fiber to.

``` bash
:ad@5GCN:~$ sudo ip link set dev enp45s0f0 up
:ad@5GCN:~$ sudo ip link set dev enp45s0f1 up
:ad@5GCN:~$ ip -br a
	:
enp45s0f0        UP             fe80::6eb3:11ff:fe08:a4e0/64 
enp45s0f1        DOWN           
	:
```

configure the static ip 10.10.0.1 of port enp45s0f0 on your server netplan (typically `/etc/netplan/50-cloud-init.yaml`) as follows: 

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

A route is added also in the routing table automatically

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
However, as mentioned, that above is the management IP address, whereas for the data interface the Benetel RRU has a different MAC on 10.10.0.2 for instance ``` 02:00:5e:01:01:01``` and we can put this on the Server where the DU runs in the file: /etc/networkd-dispatcher/routable.d/macs.sh

Add mac entry script in routable.d. 

```
$ cat /etc/networkd-dispatcher/routable.d/macs.sh 
#!/bin/sh
sudo arp -s 10.10.0.2 02:00:5e:01:01:01 -i enp45s0f0
chmod 777 /etc/networkd-dispatcher/routable.d/macs.sh
```
> Benetel650 does not answer arp requests. With this arp entry in the arp table the server knows to which mac address the ip packets with destination ip 10.10.0.2 
 should go

run the script and check now the arp table like this

```
$ arp -a | grep 10.10.0.2
? (10.10.0.2) at 02:00:5e:01:01:01 [ether] PERM on enp45s0f0
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
The version which is referred to. This is version 0.3. 
Depending on the version different configuration commands apply.
```
root@benetelru:~# cat /etc/benetel-rootfs-version 
RAN650-2V0.3
```


### Prepare the physical Benetel Radio End - Release V0.5

There are several parameters that can be checked and modified by reading writing the EEPROM, for this we recommend to make use of the original Benetel Software User Guide for RANx50-02 CAT-B O-RUs, in case of doubt ask for clarification to Accelleran Customer Support . Here we just present two of the most used parameters, that will probably need an adjustment for each deployment.

#### MAC Address of the DU

Create this script to program the mac address of the DU inside the RRU. Remember the RRU does not request arp, so we have to manually configure that. If the MAC address of the server port you use to connect to the Benetel B650 Radio End (the NIC Card port where the fiber originates from) is 00:7D:93:02:BB:FE then you can program the EEPROM of your B650 unit as follows:

```
registercontrol -w 0xC036B -x 0x88000088
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1a:0x01:0x00
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1b:0x01:0x7D
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1c:0x01:0x93
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1d:0x01:0x02
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1e:0x01:0xBB
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1f:0x01:0xFE
```

Don't forget to write lock the EEPROM again:

```
registercontrol -w 0xC036B -x 0x88000488
```

You can read the EEPROM now and double check what you did:

```
eeprog_cp60 -q -f -x -16 /dev/i2c-0 0x57 -x -r 26:6
```

**Finally, reboot your Radio End to make the changes effective**


#### Set the Frequency of the Radio End 
Create this script to program the Center Frequency in MHz of your B650 RRU. Remember to determine a valid frequency as indicated previously in the document, taking into account all the constraints and the relationship to the Offset Point A. If the Center Frequency you want to is for instance 3751,680 MHz then you can program the EEPROM of your B650 unit as follows:

```
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
```

Each byte 0x33,0x37,0x35, ... is the ascii value of a numbers 3751,680, often the calculation stops at two digits after the comma, consider the last digit always as a zero

You may then want to double check what you did by reading the EEPROM:

```
eeprog_cp60 -q -f -16 /dev/i2c-0 0x57 -r 372:8
```


Once again, this is the **CENTER FREQUENCY IN MHz that we calculated in the previous sections, and has to go hand in hand with the point A Frequency as discussed above**

Example for frequency 3751.68MHz (ARFCN=650112) you have set make sure to edit/check the pointA frequency ARFCN value back in the DU config json file in the server (in this example PointA_ARFCN=648840)

**Reboot the BNTL650 to make changes effective**


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




### Generally available checks on the B650 (all releases)

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

#### RRU Status Report
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

#### Handshake

Once the Cell and the server have been configured correctly, open two consoles and login in one of them to the server and in the other one login to the Benetel Radio End. If the cell has been just rebooted take the following two steps:

1)run the handshake command

```
handshake
```

This will trigger the cell to send periodic handshake messages every second to the server

2) login to the server and check if the handshakes are happening: these are short messages sent periodically from the B650 to the server DU MAC address that was set as discussed and can be seen with a simple tcp dump command on the fiber interface of your server (enp45s0f0 for this example):

```
tcpdump -i enp45s0f0 -c 5 port 44000 -en
19:22:47.096453 02:00:5e:01:01:01 > 6c:b3:11:08:a4:e0, ethertype IPv4 (0x0800), length 64: 10.10.0.2.44000 > 10.10.0.1.44000: UDP, length 20
```

The above shows that 10.10.0.2 (U plane default IP address of the B650 Cell)  is sending a Handshake message from the MAC address 02:00:5e:01:01:01 (default MAC address of the B650 Uplane interface) to 10.10.0.1 (Server Fiber interface IP address) on MAC 6c:b3:11:08:a4:e0 (the MAC address of that fiber interface)

Such initial message may repeat a certain number of times, this is normal.

2)Now bring the components up with docker compose

``` bash
docker-compose up -f accelleran-du-phluido/accelleran-du-phluido-2022-01-31/docker-compose-benetel.yml
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

#### Trace traffic between RRU and L1.

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

#### Troubleshooting Fiber Port not showing up
https://www.serveradminz.com/blog/unsupported-sfp-linux/

## Starting RRU Benetel 650
Perform these steps to get a running active cell.
1) Start L1 and DU (docker-compose)
2) Use wireshark to follow the CPlane traffic, at this point following sequence:
```
     DU                                        CU
      |  F1SetupRequest--->                     |
      |                    <---F1SetupResponse  |
      |			                        |
      |	          <---GNBCUConfigurationUpdate  |
      |                                         |
```
   The L1 starts listening on ip:port 10.10.0.1:44000

3) After less than 30 seconds communication between rru and du starts. The related fiber port will report around 100 Mbytes/second of traffic in both directions
 
```
     DU                                        CU
      |  GNBCUConfigurationUpdateAck--->        |
      |                                         |
```

4) type ```ssh root@10.10.0.100 handshake``` again to stop the traffic. Make sure you stop the handshake explicitly at the end of your session else, even when stopping the DU/L1 manually, the RRU will keep the link alive and the next docker-compose up will find a cell busy transmitting on the fiber and the synchronization will not happen

## Appendix: Engineering tips and tricks
### custatus
#### install
* unzip custatus.zip so you get create a directory ```$HOME/5g-engineering/utilities/custatus```
* ```sudo apt install tmux```
* create the ```.tmux.conf``` file with following content.
```
cat $HOME/.tmux.conf 
set -g mouse on
bind q killw
```
add this line in $HOME/.profile
```
export PATH=$HOME/5g-engineering/utilities/custatus:$PATH
```

#### use
to start 
```
custatus.sh tmux
```

to quit 
* type "CTRL-b" followed by "q"

> NOTE : you might need to quit the first time you have started. 
> Start a second time and see the difference.

### example

![image](https://user-images.githubusercontent.com/21971027/148368394-44fd92b2-d803-44ce-b20f-08475fb382cc.png)


