# DU Installation

The DU will be installed in several Docker containers that run on the host machine.

This chapter assumes that Docker and docker-compose have been installed and that docker can be run without superuser privileges.
See [the chapter on Kubernetes Installation](/drax-docs/kubernetes-install) for information on how to do this.

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

## Run the sysTest utility from Phluido

Create the directory to store the Phluido sysTest utility:

``` bash
mkdir Phluido_sysTest
```

Copy `Phluido_sysTest.zip` to `Phluido_sysTest` and unzip it:

``` bash
unzip Phluido_sysTest/Phluido_sysTest.zip -d Phluido_sysTest
```

Run the `sysTest` utility:

``` bash
(cd Phluido_sysTest; ./sysTest)
```

This will run a test of the system.
Once it is finsihed it produces a file `Phluido_sysTest/Phluido_sysTest.bin`.
Send this file to Accelleran, it will allow us to verify the setup of the machine is correct and provide the license key needed to run the L1 docker on the machine.

## Create a PCSCD Docker Image

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
docker run -id --privileged --name pcscd_yubikey_c -v /run/pcscd:/run/pcscd pcscd_yubikey
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

## Install the Phluido and Effnet Docker Images

Create the directories to store the Effnet and Phluido software:

``` bash
mkdir -p accelleran-du-phluido Phluido5GL1/Phluido5GL1_v0.8.1
```

Place `accelleran-du-phluido-2021-06-30.zip` in `accelleran-du-phluido` and unzip it:

``` bash
unzip accelleran-du-phluido/accelleran-du-phluido-2021-06-30.zip -d accelleran-du-phluido
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

Load the Effnet DU Docker image:

``` bash
bzcat accelleran-du-phluido/accelleran-du-phluido-2021-06-30/gnb_du_main_phluido-2021-06-30.tar.bz2 | docker image load
```

Load the Phluido L1 Docker image:

``` bash
docker build -f accelleran-du-phluido/accelleran-du-phluido-2021-06-30/phluido/docker/Dockerfile.l1 -t phluido_l1 Phluido5GL1/Phluido5GL1_v0.8.1
```

Load the Phluido RRU Docker image:

``` bash
docker build -f accelleran-du-phluido/accelleran-du-phluido-2021-06-30/phluido/docker/Dockerfile.rru -t phluido_rru Phluido5GL1/Phluido5GL1_v0.8.1
```

## Configure the DU

Create a configuration file for the Phluido RRU:

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2021-06-30/phluido/PhluidoRRU_NR_EffnetTDD_B210.cfg <<EOF
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
tee accelleran-du-phluido/accelleran-du-phluido-2021-06-30/phluido/PhluidoL1_NR_B210.cfg <<EOF
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

//License key
LicenseKey = "XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX";
EOF
```

Create a configuration file for the Effnet DU:

``` bash
tee accelleran-du-phluido/accelleran-du-phluido-2021-06-30/b210_config_20mhz.json <<EOF
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

  phluido_rru:
    image: phluido_rru
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

## Prepare the B210

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

## Start the DU

Start the DU by running the following command:

``` bash
docker-compose up -f accelleran-du-phluido/accelleran-du-phluido-2021-06-30/docker-compose.yml
```

If all goes well this will produce output similar to:

```
Starting phluido_l1_cn ... done
Recreating accelleran-du-phluido-2021-06-30_du_1 ... done
Recreating accelleran-du-phluido-2021-06-30_phluido_rru_1 ... done
Attaching to phluido_l1_cn, accelleran-du-phluido-2021-06-30_du_1, accelleran-du-phluido-2021-06-30_phluido_rru_1
phluido_l1_cn  | Reading configuration from config file "/config.cfg"...
phluido_l1_cn  | *******************************************************************************************************
phluido_l1_cn  | *                                                                                                     *
phluido_l1_cn  | *  Phluido 5G-NR virtualized L1 implementation                                                        *
phluido_l1_cn  | *                                                                                                     *
phluido_l1_cn  | *  Copyright (c) 2014-2020 Phluido Inc.                                                               *
phluido_l1_cn  | *  All rights reserved.                                                                               *
phluido_l1_cn  | *                                                                                                     *
phluido_l1_cn  | *  The User shall not, and shall not permit others to:                                                *
phluido_l1_cn  | *   - integrate Phluido Software within its own products;                                             *
phluido_l1_cn  | *   - mass produce products that are designed, developed or derived from Phluido Software;            *
phluido_l1_cn  | *   - sell products which use Phluido Software;                                                       *
phluido_l1_cn  | *   - modify, correct, adapt, translate, enhance or otherwise prepare derivative works or             *
phluido_l1_cn  | *     improvements to Phluido Software;                                                               *
phluido_l1_cn  | *   - rent, lease, lend, sell, sublicense, assign, distribute, publish, transfer or otherwise         *
phluido_l1_cn  | *     make available the PHLUIDO Solution or any portion thereof to any third party;                  *
phluido_l1_cn  | *   - reverse engineer, disassemble and/or decompile Phluido Software.                                *
phluido_l1_cn  | *                                                                                                     *
phluido_l1_cn  | *  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,           *
phluido_l1_cn  | *  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A         *
phluido_l1_cn  | *  PARTICULAR PURPOSE ARE DISCLAIMED.                                                                 *
phluido_l1_cn  | *  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,              *
phluido_l1_cn  | *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF                 *
phluido_l1_cn  | *  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)             *
phluido_l1_cn  | *  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR           *
phluido_l1_cn  | *  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS                 *
phluido_l1_cn  | *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                                       *
phluido_l1_cn  | *                                                                                                     *
phluido_l1_cn  | *******************************************************************************************************
phluido_l1_cn  |
phluido_l1_cn  | Copyright information already accepted on 2020-11-27, 08:56:08.
phluido_l1_cn  | Starting Phluido 5G-NR L1 software...
phluido_l1_cn  | 	PHAPI version       = 0.5 (12/10/2020)
phluido_l1_cn  | 	L1 SW version       = 0.8.1
phluido_l1_cn  | 	L1 SW internal rev  = r3852
phluido_l1_cn  | Parsed configuration parameters:
phluido_l1_cn  |     LicenseKey = XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX
phluido_l1_cn  |     maxNumPrachDetectionSymbols = 1
phluido_l1_cn  |     maxNumPdschLayers = 2
phluido_l1_cn  |     maxNumPuschLayers = 1
phluido_l1_cn  |     maxPuschModOrder = 6
phluido_l1_cn  |
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
