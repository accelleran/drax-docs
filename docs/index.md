# Overview

## Introduction

This guide describes the installation of the Accelleran dRax base, 4G and 5G components, the Effnet DU, Phluido L1 and optionally a core network on a single machine.

## Requirements

This installation guide assumes that that the following things are available:
* Fixed ip adress (Statically configured or fixed by the DHCP lease)
* Hardware:
	* Server with at least the following specifications:
		* Intel Xeon D-1541 or stronger 64-bit processor
		* 32 GB DDR4 RAM
		* 250 GB Hard Disk
	        * Intel Ethernet Converged Network Adapter X520
	* B210 USRP SDR Radio transiever
        * 4GB USB stick (Installation only)
* Licenses:
	* A dRAX license file: license.crt
	* A server certificate: server.crt (see the chapter on [installing dRax](/drax-docs/drax-install/) on how to get one)
	* A CA certificate: ca.crt (see the chapter on [installing dRax](/drax-docs/drax-install/) on how to get one)
	* A Phluido license key (see the chapter on [installing the DU](/drax-docs/du-install/) on how to get one)
	* A YubiKey with an activated Effnet license
* Software:
	* Ubuntu (Server) 20.04.03 LTS
	* Phluido sysTest: Phluido_sysTest.zip
	* Effnet DU: accelleran-du-phluido-2021-06-30.zip
	* Phluido L1: Phluido5GL1_v0.8.1.zip

## Hardware preperation
# First boot


# Bios settings
Pressing F2 or DEL on your keyboard immediately after booting up the server will give you access to the bios,

* Cooling settings
To ensure best preformance and minimal latency we have to change the follwing settings in the tab "performance" or "cooling".
-Set the cooling profile to performance.
-Minimum fan speed schould be set to 35%

  
* CPU and memory settings
Go to the tab > System Setup Main Menu > System BIOS > System Profile Settings.
-CPU Power Management > Maximum performance
-Memory frequency > Maximum performance
-C1E > Disabled
-C States > Disabled
-Intel Persistent Memory Performance Settin > Latency Optimized


## Installation

* [Ubuntu Server 20.04.3 Installation script](/drax-docs/automated-script/)


# TODO
This guide will refer to this IP address as `$NODE_IP` and the interface it belongs to as `$NODE_INT`.
Furthermore this guide will refer to the IP address of the gateway as `$GATEWAY_IP`, the IP address of the core (see the section on [Core Installation](/drax-docs/du-install/)) as `$CORE_IP` and the IP address of the CU (see the section on [DU Installation](/drax-docs/du-install/)) as `$CU_IP`.

In order to be able to execute the commands in this guide as-is you should add these variables to the environment as soon as they are known.
Alternatively you can edit the configurations to set the correct IP addresses.

``` bash
export NODE_IP=1.2.3.4      # replace 1.2.3.4 by the IP address of the node
export NODE_INT=enp0s3      # replace enp0s3 by the name of the network interface that has IP $NODE_IP
export GATEWAY_IP=1.2.3.1   # replace 1.2.3.1 by the IP address of the gateway
export CORE_IP=1.2.3.5      # replace 1.2.3.5 by the IP address of the core
export CU_IP=1.2.3.6        # replace 1.2.3.6 by the IP address of the CU
```

In order to perform many of the commands in this installation manual you need root privileges.
Whenever a command has to be executed with root privileges it will be prefixed with `sudo`.

## Steps

The installation process is divided in a number of steps.
Each of these steps is described in its own chapter.
It is recommended to execute these steps in the following order as there are dependencies from one chapter to another.

* [Optional: Open5GS Installation](/drax-docs/core-install/)
* [Kubernetes Installation](/drax-docs/kubernetes-install/)
* [dRax Installation](/drax-docs/drax-install/)
* [DU Installation](/drax-docs/du-install/)
