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
sudo /usr/lib/uhd/utils/uhd_images_downloader.py
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
** only for B210 **

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
tee l1-config.cfg <<EOF
/******************************************************************
 *
 * This file is subject to the terms and conditions defined in
 * file 'LICENSE'.
 *
 ******************************************************************/

// Enables verbose binary logging. WARNING: very CPU intensive and creates potentially huge output files. Use with caution.
//logLevel_verbose    = "DEBUG";

bbuFronthaulServerMode = 1;
bbuFronthaulServerAddr = "10.10.0.1"
bbuFronthaulServerPort = 44000;
/// BBU fronthaul server "busy poll" for the receive socket, in microseconds, used as value for the relevant (SOL_SOCKET,SO_BUSY_POLL) socket option.

numWorkers = 4;



// Enable 64-QAM support for PUSCH (license-specific)
maxPuschModOrder = 6;

maxNumPdschLayers = 2;
maxNumPuschLayers = 1;
maxNumPrachDetectionSymbols = 1;

targetRecvDelay_us = 2500;
//targetCirPosition = 0.0078125;

// License key
//LicenseKey = "2B2A-962F-783F-40B9-7064-2DE3-3906-9D2E"

EOF
```
**IMPORTANT: After this replace the LicenseKey value with the effective license sequence you obtained from Accelleran 


Create a configuration file for the Effnet DU:

* nr_cell_identity  ( in binary format eg 3 fill in ...00011 )
* nr_pci            ( decimal format eg 51 fill in 51 )
* plmn_identity     ( eg 235 88 fill in 235f88. fill in 2 times in this file)
* arfcn             ( decimal format calculated from the center frequency, see chapter ) 
* nr_frequency_band ( 77 or 78 )
* 5gs_tac           ( 3 byte array. eg 1 fill in 000001 ) 

``` bash
mkdir -p ~/install-$DU_VERSION/ 
cd !$
tee du-config.json <<EOF
{
    "configuration": {
        "du_address": "du",
        "cu_address": "cu",
        "gtp_listen_address": "du",
        "f1c_bind_address": "du",
        "vphy_listen_address": "127.0.0.1",
        "vphy_port": 13337,
        "vphy_tick_multiplier": 1,
        "gnb_du_id": 38209903575,
        "gnb_du_name": "cab-03-cell",
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
                        "plmn_identity": "235f88",
                        "nr_cell_identity": "000000000000000000000000000000000011"
                    },
                    "nr_pci": 2,
                    "5gs_tac": "000001",
                    "ran_area_code": 1,
                    "served_plmns": [
                        {
                            "plmn_identity": "235f88",
                            "tai_slice_support_list": [
                                {
                                    "sst": 1
                                }
                            ]
                        }
                    ],
                    "nr_mode_info": {
                        "nr_freq_info": {
                            "nr_arfcn": 662664,
                            "frequency_band_list": [
                                {
                                    "nr_frequency_band": 77
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
                    "maximum_ru_power_dbm": 53.0,
                    "num_tx_antennas": 2,
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

** remove the rru: when NOT using a b210. eg when using a b650 **

``` bash
mkdir -p ~/install-$DU_VERSION/ 
cd !$
tee docker-compose.yml <<EOF
version: "2"

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
      - "$PWD/l1-config.cfg:/config.cfg:ro"
      - "/run/logs-du/l1:/workdir"
      - "/etc/machine-id:/etc/machine-id:ro"
    working_dir: "/workdir"
    network_mode: host
    cpuset: "0,2,4,6,8,10,12,14"
    
  du:
    image: gnb_du_main_phluido:2022-07-01-q2-pre-release
    volumes:
      - "$PWD/du-config.json:/config.json:ro"
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
    cpuset: "0,2,4,6,8,10,12,14"

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

#### Start the DU

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
