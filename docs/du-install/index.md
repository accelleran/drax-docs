# DU Installation 

The DU will be installed in several Docker containers that run on the host machine.

**Before proceding further make sure Docker and docker-compose have been installed and that docker can be run without superuser privileges, this is a prerequisite.**

See, if you didn't do it already, [the chapter on Kubernetes Installation](/drax-docs/kubernetes-install) for information on how to do this.

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
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
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

1. accelleran-du-phluido-2021-09-30.zip
2. Phluido5GL1_v0.8.1.zip
3. effnet-license-activation-2021-12-16.zip 

**Note:** if you don't have yet the effnet license activation bundle, in order to obatin one you must comunicate to Accelleran the serial number of the Yubikey you intend to use so to be enabled for usage. You can obtain this information by using the following command on your server where the Yubikey has been installed phisically to a USB port:

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

Then you can find the serial number :

``` bash
~$ ykman list --serials
13134288
```

Once you have the three archive files mentioned above create the directories to store the Effnet and Phluido software:

``` bash
mkdir -p accelleran-du-phluido Phluido5GL1/Phluido5GL1_v0.8.1
```

Place `accelleran-du-phluido-2021-09-30.zip` in `accelleran-du-phluido` and unzip it:

``` bash
unzip accelleran-du-phluido/accelleran-du-phluido-2021-09-30.zip -d accelleran-du-phluido
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


### Phluido License: Run the sysTest utility from Phluido 

go to the directory where the Phluido sysTest utility is :

``` bash
cd  Phluido5GL1/Phluido5GL1_v0.8.1/tools
```
Run the `sysTest` utility:

``` bash
(cd Phluido_sysTest; ./sysTest)
```

This will run a test of the system that will allow to determine if the server is properly configured and capable of running the demanding L1/RRU components
Once it is finsihed it produces a file `sysTest.bin` in the same directory
Send this file to Accelleran, to obtain the Phluido license key


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

In order to activate the license dongles unzip the license activation bundle (effnet-license-activation-2021-12-16.zip) and then you need to load the included Docker image into your docker-daemon, i.e.

``` bash
bunzip2 --stdout license-activation-2021-06-29.tar.bz2 | docker load
```

Then run the image mapping the folder containing the `pcscd` daemon socket into
the container, e.g. for Ubuntu 20.XX:

``` bash
docker run -it --rm -v /var/run/pcscd:/var/run/pcscd effnet/license-activation-2021-12-16
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
bzcat accelleran-du-phluido/accelleran-du-phluido-2021-09-30/gnb_du_main_phluido-2021-09-30.tar.bz2 | docker image load
```

Load the Phluido L1 Docker image:

``` bash
docker build -f accelleran-du-phluido/accelleran-du-phluido-2021-09-30/phluido/docker/Dockerfile.l1 -t phluido_l1:v0.8.1 Phluido5GL1/Phluido5GL1_v0.8.1
```

**FOR B210 RU ONLY** : Load the Phluido RRU Docker image (this step does not have to be taken when using Benetel RUs):

``` bash
docker build -f accelleran-du-phluido/accelleran-du-phluido-2021-09-30/phluido/docker/Dockerfile.rru -t phluido_rru:v0.8.1 Phluido5GL1/Phluido5GL1_v0.8.1
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
mkdir accelleran-du-phluido/accelleran-du-phluido-2021-09-30/phluido/cfg
mv accelleran-du-phluido/accelleran-du-phluido-2021-09-30/phluido/*.cfg accelleran-du-phluido/accelleran-du-phluido-2021-09-30/phluido/cfg/
mkdir accelleran-du-phluido/accelleran-du-phluido-2021-09-30/json
mv accelleran-du-phluido/accelleran-du-phluido-2021-09-30/*.json accelleran-du-phluido/accelleran-du-phluido-2021-09-30/json/
rm accelleran-du-phluido/accelleran-du-phluido-2021-09-30/docker-compose.yml
```

Create a configuration file for the Phluido RRU:

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2021-09-30/phluido/PhluidoRRU_NR_EffnetTDD_B210.cfg <<EOF
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
Make sure to set the value `LicenseKey` option to the received Phluido license key:

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2021-09-30/phluido/PhluidoL1_NR_B210.cfg <<EOF
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

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2021-09-30/b210_config_20mhz.json <<EOF
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
                    "minimum_k1_delay": 3,
                    "minimum_k2_delay": 3,
                    "force_rlc_buffer_size": 112500
                }
            }
        ]
    }
}
EOF
```

Before creating the `docker-compose.yml` file, make sure to set the `$CU_IP` environment variable where you will store the F1 IP address of the CUCP that you have already deployed using the dRAX Dashboard (section [CUCP Installation](/drax-docs/drax-install/images/dashboard-cu-cp-deployment.png) )
This IP address can be determined by executing the following command:

``` bash
kubectl get services | grep f1
```
The CUCP F1 SCTP interface external address is the second IP address and should be in the IP pool that was assigned to MetalLB in [dRax Installation](/drax-docs/drax-install/).

``` bash
kubectl get services | grep f1
```

Now, create a docker-compose configuration file:

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2021-09-30/docker-compose.yml <<EOF
version: "3"

services:

  phluido_l1:
    image: phluido_l1:v0.8.1
    container_name: phluido_l1
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
    image: gnb_du_main_phluido:2021-09-30
    volumes:
      - "$PWD/b210_config_20mhz.json:/config.json:ro"
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

  phluido_rru:
    image: phluido_rru:v0.8.1
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
docker-compose up -f accelleran-du-phluido/accelleran-du-phluido-2021-09-30/docker-compose.yml
```

If all goes well this will produce output similar to:

```
Starting phluido_l1 ... done
Recreating accelleran-du-phluido-2021-09-30_du_1 ... done
Recreating accelleran-du-phluido-2021-09-30_phluido_rru_1 ... done
Attaching to phluido_l1, accelleran-du-phluido-2021-09-30_du_1, accelleran-du-phluido-2021-09-30_phluido_rru_1
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

