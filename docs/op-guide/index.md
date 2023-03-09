
# Accelleran Operational User Guide 

## 1. Introduction

This guide describes how to operate the Accelleran ORAN 5G  Platform and its RIC, CU, DU and L1 components. The scope of this document is therefore to cover only the operational aspects of our platform, including the basic configuration and examples of some test cases. 

This of course means that the installation and initial configuration of the System has been already made by Accelleran Customer Support and there is no need to worry about how to prepare the server, install and initialise the components, and so on.

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
Here a simplified diagram of all network components and the related ip addresses, the effective network diagram can be rather different from case to case, here we intedn to illustrate the principles and the default standard setup configuration, as an example.

Before you continue you may want to derive the real schema and fill in this simplified drawing with the actual components and ip address that apply for your configuration.

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
                                  │ │          enp7s0                  │                                     │
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
                                  │ │                           enp1s0                                       │ │
                                  │ │ VM RIC/CU/CellWrapper                                                                │ │
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
### 3.1. Basic Cell Operations

Basic cell operation like start, stop, restart. Or locking and unlocking the CU can all be done through the dashboard.
- The dashboard can be accessed via https://"RIC/CU_VM_IP":31315
- From the dashbord go to **RAN Overview** then select **5G**.

<p align="center">
  <img src="cu-configuration/config_view.png">
</p>



### 3.2. Cell Monitoring
From the home window you can view the cell when it goes live and the UEs attached to it.

<p align="center">
  <img src="cu-configuration/topology_view.png">
</p>

The DRAX dashboard also uses grafana to view measurements and Counters.
- This can be accessed via https://"RIC/CU_VM_IP":30300
- A number of reports will be readily available on this release as an example:
    - Radio Condition and Throughput can be viewed in the "5G UE Monitoring" dashboard. 
    - Accessibility and Mobility Counters (e.g. Number of RRC Attempts or Number of Handover Execution Successes) can be viewed in the "5G PM Counters" dashboard.


## 4. More Cell Operations

Below sections will give more information.

* [CU Configuration](cu-configuration/index.md)
* [RU/DU Configuraiton](modifying-ran650-or-ran550/index.md)
* [Handover Configuration](handover-configuration/index.md)
* [MOCN and Slicing](mocn-and-slicing/index.md)
* [Logs Collection](logs-collection/index.md)
