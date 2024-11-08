# SystemRelease 2024.2.0

## 1. Releases

This document is released together with the system release 2024.2.0 which containes:

| RAN | Component | Version |
|-|-|-|
| | DRAX | 11.0.0 |
| | xApp SDK | 5.0.0 |
| | CU CHART | 9.0.4 |
| | CU APP | 6.0.7 |
| | Cell Wrapper | 6.0.2 |
| | Cell Wrapper config | 0.5.1 |
| RAN3 | Accelelran DU | 3.0.1 |
| RAN3 | BNTL650-CATA | RAN650-1v1.0.4-dda1bf5 |
| RAN3 | BNTL550-CATA | RAN550-1v1.0.4-605a25a |
| CORE | open5gs | 2.7.2 |


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
* [DRAX Deployment](/drax-docs/drax/11.0.0/)
* [CU Deployment](/drax-docs/cu/6.0.7/)
* [Cell Wrapper Deployment](/drax-docs/cw/0.5.0/)

If a core to be installed:

* [Core Installation](/drax-docs/core/v2.7.2/)

Depending on the RAN to be installed:

* [RAN3: AccelleranDU Preparation](/drax-docs/ran3_accelleran_benetel/3.0.1/)
