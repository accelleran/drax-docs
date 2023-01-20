new op guide

# Accelleran CU Install Guide 

## Introduction

This guide describes the installation of the Accelleran dRAX base, 4G and 5G components, the Effnet DU, Phluido L1 and optionally a core network on a single server machine, however separating the RIC/CU (on a VM) and the DU/L1 (on the server) to increase stability and performances.

This first page is the most important page of the install. This first pages holds all the elements needed to do the install in a minimum of time.  

## Duration
This install can be done in  1 day up to 1 week depending on the experience of the engineer. This is an estimation done from experience. Why this is the case is not explained here. However a few points listed here without any more details.

* Slight differences in hardware/firmware of each component.
* The network the platform resides in.
* The experience and view points of the engineer itself.
* Network stability in which the platform resides.
* Access to the platform.
* ...
  
Because the install is done manually by an engineer it might be necessary that this engineer needs some support from accelleran.


## Releases
This document is released together with the system release 2022.3.0. 
This system release contains 

| component    | version                     |
|--------------|-----------------------------|
| RIC          | 6.0.0                       |
| CU CHART     | 5.0.0                       |
| CU APP       | R3.3.0_hoegaarden           |
| DU           | 2022-08-26-q2-release-0.4   |
| L1           | 8.4.2                       |
| BNTL650      | 0.5.2                       |
| BNTL550      | 0.6.0                       |
| cell wrapper | 1.0.0                       |


## network components overview
Here a simplified diagram of all network components and the related ip addresses. 
Before you continue installing fill in this simplified drawing with the ip address that apply for the configuration.

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

* [Kubernetes Installation](/drax-docs/op-guide/DU-L1 Update/)
* [dRax Installation](/drax-docs/drax-install/)
* [DU Installation](/drax-docs/du-install/)
