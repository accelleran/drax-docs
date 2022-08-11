# Overview

## Introduction

This guide describes the installation of the Accelleran dRAX base, 4G and 5G components, the Effnet DU, Phluido L1 and optionally a core network on a single server machine, however separating the RIC/CU (on a VM) and the DU/L1 (on the server) to increase stability and performances

## Prerequisites

This installation guide assumes that that the following are to be taken as prerequisites and made available before proceding further:

* Hardware:
	* Server with at least the following specifications:
		* Intel Xeon D-1541 or stronger 64-bit processor
		* 64 GB DDR4 RAM
		* 800 GB Hard Disk
	* VM within the Server, in the same subnet with at least :
		* 8 assigned cores
		* 32 GB assigned RAM
		* 200 GB assigned Disk space  
* Licenses:
	* A dRAX license file: license.crt
	* 4G Only:  A server certificate: server.crt (see the chapter on [installing dRax](/drax-docs/drax-install/) on how to get one)
	* 4 G Only: A CA certificate: ca.crt (see the chapter on [installing dRax](/drax-docs/drax-install/) on how to get one)
	* A Phluido license key (see the chapter on [installing the DU](/drax-docs/du-install/) on how to get one)
	* Effnet YubiKey 
	* Effnet yubikey license activation file: effnet-license-activation-2022-07-01.zip
	* an active github account that has been enabled to access the necessary software images on accelleran github repository
	
* Software:
	* Ubuntu Server 20.04 OS both on the VM and on the Server 
	* Effnet DU: accelleran-du-phluido-2022-07-01-q2-pre-release.zip
	* Phluido L1: phluido_docker_0842.tar
	* effnet-license-activation-yyyy_mm_dd.zip
	* sysTest executable 

NOTE: while taking almost no active time to obtain the Phluido license code and the Effnet activation bundle, in order to do so we need to contact our technical partners and this may require up to a couple of working days so it is recommended to take the necessary actions to complete these steps first of all. Similarly, we must enable your dockerhub account to access and download the Accelleran software images, this also takes some time and can be done upfront


## Preparation

### know the ip addresses
Make sure Ubuntu (Server) 20.04 is installed as said both on the physical server and on the virtual machine and that both have access to the internet.
They both must have a static IP address on a fixed port, in the same subnet
This guide will refer to the VM static IP address as `$NODE_IP` and the interface it belongs to as `$NODE_INT`, and to $SERVER_IP for the server static IP address.
Furthermore this guide will refer to the IP address of the gateway as `$GATEWAY_IP`, the IP address of the core (see the section on [Core Installation](/drax-docs/core-install/)) as `$CORE_IP` and the IP address of the CU (see the section on [DU Installation](/drax-docs/du-install/)) as `$CU_IP`.
In order to be able to execute the commands in this guide as-is you should add these variables to the environment as soon as they are known.
Alternatively you can edit the configurations to set the correct IP addresses. 

``` bash
export NODE_IP=192.168.88.4       # replace 192.168.88.4 by the IP address of the node
export NODE_INT=eno1              # replace enp0s3 by the name of the network interface that has IP $NODE_IP
export GATEWAY_IP=192.168.88.1    # replace 192.168.88.1 by the IP address of the gateway
export CORE_IP=192.168.88.5       # replace 192.168.88.5 by the IP address of the core
export F1_CU_IP=192.168.88.171    # F1 ip address the CU listens on. ( used in port range of the loadbalancer and creation of the CUCP)
export E1_CU_IP=192.168.88.170    # E1 ip address the CU listens on. ( used in port range of the loadbalancer and creation of the CUCP)
export SERVER_IP=192.168.88.3     # The IP address of the linux bridge ( br0 )
export RU_INT=enp1s0f0            # interface of the server to the RU. Fiber interface.
```

In order to perform many of the commands in this installation manual you need root privileges.
Whenever a command has to be executed with root privileges it will be prefixed with `sudo`.

## network components
Here a simplification of all network components and the related ip addresses. 

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
                                  │ │ VM CU                                                                │ │
                                  │ │ NODE_IP=192.168.88.4                                                 │ │
                                  │ │                                                                      │ │
                                  │ │                                                                      │ │
                                  │ │                                                                      │ │
                                  │ │                                                                      │ │
                                  │ │                                                                      │ │
                                  │ │       E1                 F1              GTP-0             GTP-1     │ │
                                  │ │    E1_CU_IP           F1_CU_IP                                       │ │
                                  │ │192.168.88.170     192.168.88.171    192.168.88.172    192.168.88.173 │ │
                                  │ └──────────────────────────────────────────────────────────────────────┘ │
                                  │                                                                          │
                                  │                 ┌────────────────────┐                                   │
                                  │                 │DU effnet docker    │                                   │
                                  │                 │                    │                                   │
                                  │                 │                    │                                   │
                                  │                 │                    │                                   │
                                  │                 └────────────────────┘                                   │
                                  │                                                                          │
                                  │                 ┌────────────────────┐                                   │
                                  │                 │L1 phluido docker   │                                   │
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

## Steps

The installation process is divided in a number of steps.
Each of these steps is described in its own chapter.
It is recommended to execute these steps in the following order as there are dependencies from one chapter to another.

* [Optional: Open5GS Installation](/drax-docs/core-install/)
* [Kubernetes Installation](/drax-docs/kubernetes-install/)
* [dRax Installation](/drax-docs/drax-install/)
* [DU Installation](/drax-docs/du-install/)
