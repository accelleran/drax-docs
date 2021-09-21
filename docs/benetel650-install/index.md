## Configure the DU

Other then the B210, benetel uses 2 software components. 2 Containers, a effnet du and phluido l1.
The phluido rru is not needed. This component resides in the benetel equipment.

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

## Prepare the Benetel 560

The benetel is connected with a fiber to the server.


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

The ip benetel is configured with is `10.10.0.100`.
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
