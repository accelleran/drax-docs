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
	* A YubiKey with an activated Effnet license
* Software:
	* Ubuntu (Server) 20.04
	* Effnet DU: accelleran-du-phluido-2022-07-01-q2-pre-release
	* Phluido L1: phluido_docker_0842


## Preparation

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
export CU_IP=192.168.88.171       # F1 ip address the CU listens on. 
```

In order to perform many of the commands in this installation manual you need root privileges.
Whenever a command has to be executed with root privileges it will be prefixed with `sudo`.

## network components
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
                                  │ │      E1                 F1               GTP-0             GTP-1     │ │
                                  │ │                       CU_IP                                          │ │
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
                                  │                             enp1s0f0 10.10.0.1                           │
                                  └────────────────────────────┬─────────────────────────────────────────────┘
                                                               │
                                                               │ fiber
                                                    ┌──────────┴────────────────────────┐
                                                    │ RU        eth0 10.10.0.100 mgmt   │
                                                    │                10.10.0.2   traffic│
                                                    │                                   │
                                                    │                                   │
                                                    │                                   │
                                                    │                                   │
                                                    └───────────────────────────────────┘


```
## Steps

The installation process is divided in a number of steps.
Each of these steps is described in its own chapter.
It is recommended to execute these steps in the following order as there are dependencies from one chapter to another.

* [Optional: Open5GS Installation](/drax-docs/core-install/)
* [Kubernetes Installation](/drax-docs/kubernetes-install/)
* [dRax Installation](/drax-docs/drax-install/)
* [DU Installation](/drax-docs/du-install/)
