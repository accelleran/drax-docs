
# Operational User Guide 

## 1. Introduction

This guide describes how to operate the Accelleran ORAN 5G  Platform and the different network components (RIC, CU, DU and L1). The scope of this document is therefore to cover only the operational aspects of the platform, including the basic configuration and examples of some test cases. 

This means that the installation and initial configuration of the System has been already made by Accelleran Customer Support and there is no need to worry about how to prepare the server, install and initialise the components.

## 2. Releases
This document is released together with the system release 2022.4.0. 
This system release contains 

| component    | version                        |
|--------------|--------------------------------|
| RIC          | 6.2.0                          |
| CU CHART     | 5.1.0                          |
| CU APP       | R3.4.1_ichtegem                |
| DU           | 2023-02-14-q4-patch-release-01 |
| L1           | 8.8.1                          |
| BNTL650      | 0.5.3                          |
| BNTL550      | 0.6.0                          |
| cell wrapper | 2.0.0                          |


## 3. Dashboard

The dashboard can be accessed via https://"RIC_CU_VM_IP":31315

### 3.1. Basic Cell Operations

Basic cell operation like start, stop, restart. Or locking and unlocking the CU can all be done through the dashboard.

- From the dashbord go to **RAN Overview** then select **5G**.

<p align="center">
  <img src="cu-configuration/config_view.png">
</p>



### 3.2. Cell Monitoring
From the **Home** tab the cell status can be monitored and the UEs attached to it.

<p align="center">
  <img src="cu-configuration/topology_view.png">
</p>

The DRAX dashboard also uses grafana to view measurements and Counters.

- This can be accessed via https://"RIC_CU_VM_IP":30300
- A number of reports will be readily available on this release as an example:
    - Radio Condition and Throughput can be viewed in the **5G UE Monitoring** dashboard. 
    - Accessibility and Mobility Counters (e.g. Number of RRC Attempts or Number of Handover Execution Successes) can be viewed in the **5G PM Counters** dashboard.


## 4. More Cell Operations

Below sections will give more information.

* [CU Configuration](cu-configuration/index.md)
* [RU/DU Configuraiton](modifying-ran650-or-ran550/index.md)
* [Handover Configuration](handover-configuration/index.md)
* [MOCN and Slicing](mocn-and-slicing/index.md)
* [Logs Collection](logs-collection/index.md)
