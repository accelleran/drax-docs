# SystemRelease 2024.1.0

## 1. Releases

This document is released together with the system release 2024.1.0 which containes:

| RAN | Component | Version |
|-|-|-|
| | DRAX | 8.0.1 |
| | CU CHART | 8.0.2 |
| | CU APP | 5.0.7 |
| | Cell Wrapper | 4.0.0 |
| | Cell Wrapper config | 0.3.0 |
| RAN1 | Effnet DU | 2024-06-14-q3-patch-release-02-8.9.3 |
| RAN1 | Phluido UL1 | 8.12.1 |
| RAN1 | BNTL650-CATB| RAN650-2V0.8.1 |
| RAN1 | BNTL550-CATB | RAN550-2-V0.8.1 |
| RAN2 | NodeH DU | 5.2.1-32888 |
| RAN3 | Accelelran DU | 1.0.4 |
| RAN3 | BNTL650-CATA | RAN650-1v1.0.4-dda1bf5 |


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
    * RAN1 extra license requirements:
        * Effnet YubiKey USB Stick
        * Effnet yubikey license activation file
    * An active dockerhup account that has been allowed to access the necessary software images on accelleran dockerhub repositories

## 3. Example Network Components Overview

Here a simplified diagram of all network components and the related ip addresses, that would be used for the rest of this guide.

<p align="center">
  <img src="/drax-docs/images/01_NetworkOverview.png">
</p>

> Above example is for RAN3 when deploying a single server setup.

### **Steps to take**

The installation process is divided in a number of steps.
Each of these steps is described in its own chapter.
It is recommended to execute these steps in the following order as there are dependencies from one chapter to another.

* [Server Preperation](prep_machine/index.md)
* [Prepare the Kubernetes Cluster](/drax-docs/K8s/1.24/)
* [DRAX Deployment](/drax-docs/drax/8.0.1/)
* [CU Deployment](/drax-docs/cu/5.0.7/)
* [Cell Wrapper Deployment](/drax-docs/cw/0.3.0/)

If a core to be installed:

* [Core Installation](/drax-docs/core/from_apt_packages/)

Depending on the RAN to be installed:

* [RAN1: EffnetDU-Phluido Preparation](/drax-docs/ran1_effnet_phluido_benetel/2024.1.0/)
* [RAN2: NodehDU/RU](/drax-docs/ran2_nodeh/5.2.1-32888/)
* [RAN3: AccelleranDU Preparation](/drax-docs/ran3_accelleran_benetel/1.0.4/)
