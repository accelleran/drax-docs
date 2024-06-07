# SystemRelease 2023.3.1

## 1. Releases

This document is released together with the system release 2023.3.1 which containes:

| RAN | Component | Version |
|-|-|-|
| | DRAX | 7.1.0 |
| | CU CHART | 7.1.0 |
| | CU APP | R4.3.16_leffe |
| | cell wrapper config | 0.2.4 |
| RAN1 | Effnet DU | 2024-01-31-q3-patch-release-01-8.7.4 |
| RAN1 | Phluido UL1 | 8.7.4 |
| RAN1 | BNTL650 | 0.7.0 |
| RAN1 | BNTL550 | 0.7.1 |
| RAN2 | NodeH DU | 5.1.0.32092 |


## 2. Prerequisites

This installation guide assumes that that the following are to be taken as prerequisites and made available before proceding further:

* **Hardware**:
    * Server with at least the following specifications:
        * ***Missing super micro server details***

* **Software**:
    * Ubuntu Server 22.04 OS installed on the server and VMs.
    * Access to the internet for the server and the VMs.

* **Licenses**:
    * A dRAX license file: license.crt
    * RAN1:
        * A Phluido license key
        * Effnet YubiKey USB Stick
        * Effnet yubikey license activation file
    * An active dockerhup account that has been allowed to access the necessary software images on accelleran dockerhub repositories

## 3. Example Network Components Overview

Here a simplified diagram of all network components and the related ip addresses, that would be used for the rest of this guide.

<p align="center">
  <img src="/drax-docs/images/01_NetworkOverview.png">
</p>

> Above example is using CAT_B RU. For CAT_A RU there would be a PTP enabled switch between the DU and RU.

### **Steps to take**

The installation process is divided in a number of steps.
Each of these steps is described in its own chapter.
It is recommended to execute these steps in the following order as there are dependencies from one chapter to another.

* [Server Preperation](prep_machine/index.md)
* [Prepare the Kubernetes Cluster](/drax-docs/K8s/1.24/)
* [DRAX Deployment](/drax-docs/drax/7.1.0/)
* [CU Deployment](/drax-docs/cu/R4.3.16_leffe/)
* [Cell Wrapper Deployment](/drax-docs/cw/0.2.4/)

If a core to be installed:

* [Core Installation](/drax-docs/core/from_apt_packages/)

Depending on the RAN to be installed:

* [RAN1: EffnetDU-Phluido Preparation](/drax-docs/ran1_effnet_phluido_benetel/2023.3.0/)
* [RAN2: NodehDU/RU](/drax-docs/ran2_nodeh/5.2.1-32888/)
