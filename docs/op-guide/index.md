
# Accelleran Operational User Guide 

## Introduction

This guide describes how to operate the Accelleran ORAN 5G  Platform and its RIC , CU, DU and L1 components. The scope of this document is therefore to cover only the operational aspects of our platform, including the configuration and the routinary and periodic update of it. 

This of course means that the installation and initial configuration of the System has been already made by Accelleran Customer Support and there is no need to worry about how to prepare the server, install and initialise the components, and so on.

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


## network components overview
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

## Available Sections

The Operational User Guide is divided mainly in three different subjects: System Configuration, Start/Stop of the System, Components Update.
Each of these steps is described in its own chapter.


* [Appendix A]("/drax-docs/docs/op-guide/appendix-a/index.md")
* [Appendix B](appendix-b/index.md)
* [Configure and bring Ettus B210 on air](/drax-docs/op-guide/bring-B210-on-air)
<!-- [Configure and bring Ettus X310 on air] (TBD)-->
* [Configure and bring Benetel 550 on air](/drax-docs/op-guide/bring-Benetel-550-on-air)
* [Configure and bring Benetel 650 on air](/drax-docs/op-guide/bring-Benetel-650-on-air)
* [CU Configuration]("/drax-docs/docs/op-guide/cu-configuration/")
* [Handover Configuration](/drax-docs/op-guide/handover-configuration)
* [MOCN and Slicing](/drax-docs/op-guide/mocn-and-slicing)
* [DU and L1 Update](/drax-docs/op-guide/du-l1-update)
* [RIC Update](/drax-docs/op-guide/ric-update/)


