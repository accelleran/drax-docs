
# Accelleran Internal Install Guide 

## Introduction

This guide describes the installation procedure for RIC 4G and 5G components, the DU, and L1 on a single server machine, however separating the RIC/CU (on a VM) and the DU/L1 (on the server) to increase stability and performances.
This document is for internal use and takes several steps as  granted for an Accelleran engineer and shall not be shared with Customers unless a different agreement is taken case by case. These first pages holds all the elements needed to do the install in a minimum of time.  

## Releases
This document is released together with the system release 2022.3.1. 
This system release contains 

| component    | version                     |
|--------------|-----------------------------|
| RIC          | 6.1.0                       |
| CU CHART     | 5.1.0                       |
| CU APP       | R3.3.2_hoegaarden           |
| DU           | 2022-08-26-q3-release-0.2   |
| L1           | 8.7.4                       |
| BNTL650      | 0.5.3                       |
| BNTL550      | 0.6.0                       |
| cell wrapper | 1.1.0                       |

During the installation one may or may not use all or some of the following variables. These are the correct values they are set to for this release:

``` bash
export INSTALL_VERSION=2022.3.1
export RIC_VERSION=6.1.0
export CU_VERSION=R3.3.2_hoegaarden             # build tag
export L1_VERSION=v8.7.4
export DU_VERSION=2022-08-26-q3-release-0.2
export RU_VERSION=RAN650-2V0.5.3                # shipped with the UNIT.
```

## Prerequisites / Preperations

This installation guide assumes that that the following are to be taken as prerequisites and made available before proceding further:

* Hardware:
	* Server with at least the following specifications:
		* Intel Xeon D-1541 or stronger 64-bit processor
		* 64 GB DDR4 RAM
		* 800 GB Hard Disk
		* BIOS settings to most performance mode ( powersaving off, )
	* VM within the Server, in the same subnet with at least :
		* 8 assigned cores
		* 32 GB assigned RAM
		* 200 GB assigned Disk space  
           >
    The VM MUST be created using KVM/Virsh, this allows to have easy access to its libvirt XML configuration when needed, ex. to perform the CPU pinning

* Licenses:
	* A dRAX license file: license.crt
  * If your setup uses the Phluido/Effnet Stack: 
	    Phluido license key (see the chapter on [installing the DU](/drax-docs/du-install/) on how to get one)
      Effnet YubiKey 
      Effnet yubikey license activation file: effnet-license-activation-yyyy-mm-dd.zip
	* an active github account that has been enabled to access the necessary software images on accelleran github repository
	
* Linux Configuration:
    * Linux bridge br0
    
* 5G configuration :
	* plmn_identity [ eg 235 88 ]
	* nr_cell_identity [ eg 1 any number ]
	* nr_pci [ eg 1 not any number. Make sure to do the correct PCI planning in case of multiple cells. ]
	* 5gs_tac [ eg 1 ]
	* center_frequency_band [ eg 3751.680 ]
	* point_a_arfcn [ eg 648840 consistent with center freq, scs 30khz ]
	* band [ eg 77 consistent with center frequency ]
    
> NOTE: while taking almost no active time to obtain the Phluido license code and the Effnet activation bundle, in order to do so we need to contact our technical partners and this may require up to a couple of working days so it is recommended to take the necessary actions to complete these steps first of all. Similarly, we must enable your dockerhub account to access and download the Accelleran software images, this also takes some time and can be done upfront


### Know the ip addresses, interfaces, user account
Make sure Ubuntu (Server) 20.04 is installed as said both on the physical server and on the virtual machine and that both have access to the internet.
They both must have a static IP address on a fixed port, in the same subnet

> NOTE : All IP's need to be in the same subnet. Here we describe and define the typical parameters that need to be set on each deployment and one can optionally set them as environment variables to expedite the installation. The ip's and values used in the variables depicted below are example values.

> NOTE : the USER of the CU VM and the bare metal HOST is assumed to be the same.   

``` bash
export NODE_IP=192.168.88.4          # replace 192.168.88.4 by the IP address of the node. ( The IP of the eth0 in the CU VM )
export NODE_SUBNET=192.168.88.0/24   # the subnet that contains the $NODE_IP
export NODE_INT=br0               # he name of the network interface that has IP $NODE_IP
export SERVER_IP=192.168.88.3     # The IP address of the linux bridge ( br0 )
export SERVER_INT=eno1             # The physical interface the server connects to the LAN.
export GATEWAY_IP=192.168.88.1    # replace 192.168.88.1 by the IP address of the gateway
export CORE_IP=192.168.88.5       # replace 192.168.88.5 by the IP address of the core
export E1_CU_IP=192.168.88.170    # E1 ip address the CU listens on. Good practice to take the second last in the LOADBALANCER_IP_RANGE and anding with an even byte.
export F1_CU_IP=192.168.88.171    # F1 ip address the CU listens on. Good practice to take the last in the LOADBALANCER_IP_RANGE and ending with an odd byte.
export LOADBALANCER_IP_RANGE=192.168.88.160-192.168.88.171
export POD_NETWORK="10.244.0.0/16"

export USER=user                  # username to log into linux of HOST SERVER and CU VM
export CU_HOSTNAME=cu-cab3        # the hostname the CU VM will get.
export CU_VM_NAME=cu-cab3         # the hostname the CU VM will get.
export OPEN5GS_HOSTNAME=open5gs-cab3        # the hostname the CU VM will get.
export OPEN5GS_VM_NAME=open5gs-cab3         # the hostname the oCU VM will get.
export L1_PHLUIDO_KEY="xxxx.xxxx.xxxx.xxxx.xxxx"

```

In case a Benetel650 RU connected to the server with a fiber
``` bash
export SERVER_RU_INT=enp1s0f0            # interface of the server to the RU. Fiber interface.
export MAC_DU=11:22:33:44:55:66          # mac of the server interface to RU.
export MAC_RU=aa:bb:cc:dd:ee:ff      # mac of the RU for ip 10.0.0.2. Use tcpdump to find.
```

```

In order to perform many of the commands in this installation manual you need root privileges. Make sure the user on can do sudo without password (if tom is the user name):

``` bash
sudo visudo
tom ALL=(ALL) NOPASSWD:ALL
``` 
It is recommended to do this both on the server and the VM

> NOTE : for multiple cells bare in mind a correct PCI ID planning.

### know which cores and cpu you will be using.
Depending on the server you will be using assign the cores to the DU and CU.

> IMPORTANT : only comma seperated list is allowed. ( virt-install will be using it )

##### In case of dual CPU
``` bash
ubuntu@bbu3:~$ numactl --hardware
available: 2 nodes (0-1)
node 0 cpus: 0 2 4 6 8 10 12 14
node 0 size: 64037 MB
node 0 free: 593 MB
node 1 cpus: 1 3 5 7 9 11 13 15
node 1 size: 64509 MB
node 1 free: 138 MB
node distances:
node   0   1 
 0:  10  21 
 1:  21  10 
```
assign all cores of 1 CPU to DU. The cores of the other CPU to CU VM). 

``` bash
export CORE_SET_DU=0,2,4,6,8,10,12,14
export CORE_SET_CU=1,3,5,7,9,11,13,15
export CORE_AMOUNT_CU=8
```

##### In case of 1 CPU server
``` bash
$ numactl --hardware
available: 1 nodes (0)
node 0 cpus: 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19
node 0 size: 31952 MB
node 0 free: 4294 MB
node distances:
node   0 
  0:  10 
``` 
Assign first half to DU and last half to CU
``` bash
export CORE_SET_DU=0,1,2,3,4,5,6,7,8,9
export CORE_SET_CU=10,11,12,13,14,15,16,17,18,19
export CORE_AMOUNT_CU=10
```

## Prepare install directory and scripts
 Create an install directory in which we'll be working through this whole install procedure. 

``` bash
git clone --branch $INSTALL_VERSION https://github.com/accelleran/drax-install
```
## network components overview
Here a simplified diagram of all network components and the related ip addresses. 
Before you continue installing fill in this simplified drawing with the ip address that apply for the configuration.

> NOTE : the CORE needs to be able to reach the GTP-0  and GTP-1 ips. In this example they are in the same subnet.

> NOTE : subnet in below example is 255.255.255.0

```


                                  ┌──────────────────────────────────────────────────────────────────────────┐
                                  │                                                                          │
                                  │ server                                                                   │
                                  │                                                                          │
                                  │ ┌──────────────────────────────────┐                                     │
                                  │ │ VM CORE                          │                                     │
                                  │ │ CORE_IP 192.168.88.5             │                                     │
                                  │ │                                  │                                     │
                                  │ │                                  │                                     │
                                  │ │                                  │                                     │
                                  │ │                                  │                                     │
                                  │ │          enp1s0                  │                                     │
                                  │ └─────────────────────────────┬────┘                                     │
                                  │                               │                                          │
                                  │                               │                                          │
                                  │                               │                                          │
                                  │                               │                                          │
                                  │                               │                                          │
       internet access            │                               │                                          │
                                  │                               │                                          │
    GATEWAY_IP 192.168.88.1       │                               ▼                                          │
     ◄────────────────────────────┤ eno1  ───────────────► ( linux bridge br0 192.168.88.3 )                 │
                                  │                               ▲                                          │
                                  │                               │                                          │
                                  │                               │                                          │
                                  │                               │                                          │
                                  │ ┌─────────────────────────────┴────────────────────────────────────────┐ │
                                  │ │                           eth0                                       │ │
                                  │ │ VM CU                                                                │ │
                                  │ │ NODE_IP=192.168.88.4                                                 │ │
                                  │ │                                                                      │ │
                                  │ │                                                                      │ │
                                  │ │       E1                 F1              GTP-0             GTP-1     │ │
                                  │ │    E1_CU_IP           F1_CU_IP                                       │ │
                                  │ │192.168.88.170     192.168.88.171    192.168.88.172    192.168.88.173 │ │
                                  │ └──────────────────────────────────────────────────────────────────────┘ │
                                  │                                                                          │
                                  │                 ┌────────────────────┐                                   │
                                  │                 │DU effnet container │                                   │
                                  │                 │                    │                                   │
                                  │                 │                    │                                   │
                                  │                 │                    │                                   │
                                  │                 └────────────────────┘                                   │
                                  │                                                                          │
                                  │                 ┌────────────────────┐                                   │
                                  │                 │L1 phluido container│                                   │
                                  │                 │                    │                                   │
                                  │                 │                    │                                   │
                                  │                 │                    │                                   │
                                  │                 └────────────────────┘                                   │
                                  │                             enp1s0f0 10.10.0.1/24                        │
                                  └────────────────────────────┬─────────────────────────────────────────────┘
                                                               │
                                                               │ fiber
                                                    ┌──────────┴───────────────────────────┐
                                                    │ RU        eth0 10.10.0.100/24 mgmt   │
                                                    │                10.10.0.2/24   traffic│
                                                    │                                      │
                                                    │                                      │
                                                    │                                      │
                                                    │                                      │
                                                    └──────────────────────────────────────┘


```

## Steps to take

The installation process is divided in a number of steps.
Each of these steps is described in its own chapter.
It is recommended to execute these steps in the following order as there are dependencies from one chapter to another.

* [Optional: Open5GS Installation](/drax-docs/core-install/)
* [Kubernetes Installation](/drax-docs/kubernetes-install/)
* [dRax Installation](/drax-docs/drax-install/)
* [DU Installation](/drax-docs/du-install/)
