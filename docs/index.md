# Overview

## Introduction

This guide describes the installation of the Accelleran dRax base, 4G and 5G components, the Effnet DU, Phluido L1 and optionally a core network on a single machine.

## Prerequisites

This installation guide assumes that that the following things are available:

* Hardware:
	* Server with at least the following specifications:
		* Intel Xeon D-1541 or stronger 64-bit processor
		* 64 GB DDR4 RAM
		* 800 GB Hard Disk
	* B210 USRP
* Licenses:
	* A dRAX license file: license.crt
	* A server certificate: server.crt (see the chapter on [installing dRax](/drax-docs/drax-install/) on how to get one)
	* A CA certificate: ca.crt (see the chapter on [installing dRax](/drax-docs/drax-install/) on how to get one)
	* A Phluido license key (see the chapter on [installing the DU](/drax-docs/du-install/) on how to get one)
	* Effnet YubiKey 
	* Effnet yubikey license activation file: effnet-license-activation-2022-07-01.zip
	
* Software:
	* Ubuntu (Server) 20.04
	* Effnet DU: accelleran-du-phluido-2022-07-01-q2-pre-release
	* Phluido L1: phluido_docker_0842.tar
	* sysTest executable 

## Preparation

### know the ip addresses
Make sure Ubuntu (Server) 20.04 is installed on the machine and that it has access to the internet.
The IP address assigned to it should be fixed.
This guide will refer to this IP address as `$NODE_IP` and the interface it belongs to as `$NODE_INT`.
Furthermore this guide will refer to the IP address of the gateway as `$GATEWAY_IP`, the IP address of the core (see the section on [Core Installation](/drax-docs/core-install/)) as `$CORE_IP` and the IP address of the CU (see the section on [DU Installation](/drax-docs/du-install/)) as `$CU_IP`.
In order to be able to execute the commands in this guide as-is you should add these variables to the environment as soon as they are known.
Alternatively you can edit the configurations to set the correct IP addresses. 

``` bash
export NODE_IP=192.168.88.4       # replace 1.2.3.4 by the IP address of the node
export NODE_INT=eno1              # replace enp0s3 by the name of the network interface that has IP $NODE_IP
export GATEWAY_IP=192.168.88.1    # replace 1.2.3.1 by the IP address of the gateway
export CORE_IP=192.168.88.5       # replace 1.2.3.5 by the IP address of the core
export F1_CU_IP=192.168.88.171       # F1 ip address the CU listens on. ( used in port range of the loadbalancer and creation of the CUCP)
export E1_CU_IP=192.168.88.170    # E1 ip address the CU listens on. ( used in port range of the loadbalancer and creation of the CUCP)
```

In order to perform many of the commands in this installation manual you need root privileges.
Whenever a command has to be executed with root privileges it will be prefixed with `sudo`.

### Phluido License: Run the sysTest utility from Phluido
go to the directory where the Phluido sysTest utility is :

```
$ ./sysTest 
Running system test...
01234567890123456789012345678901
System test completed, output written to file "sysTest.bin".
```

( The test takes around 90 seconds) This will run a test of the system that will allow to determine if the server is properly configured and capable of running the demanding L1/RRU components Once it is finsihed it produces a file sysTest.bin in the same directory Send this file to Accelleran, 
to obtain the Phluido license key. Send this .bin file to phluido to receive a proper license.


## network components
Here a simplification of all network components and the belonging ip addressen. 

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
