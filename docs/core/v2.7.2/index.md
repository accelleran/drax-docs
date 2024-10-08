# Core Installation

If you already have a core you can skip this chapter.

> PS: All the following steps and sections won't be needed in case of using ansible. Guide available in [5G Integration Repo](https://github.com/accelleran/5g-integration/tree/main/utilities/install_tools/ansible)

> PS: From the [Example Network Diagram](/drax-docs/SystemRelease/2024.1.0/#3-example-network-components-overview) the VM IP is 10.55.5.4.

> All below steps would be implemented on the CORE VM.


## 1. Install Open5GS


This [Install Script](open5gs_install_script_from_sources.sh) can be used to install v2.7.2


## 2. Configure Open5GS

The default configuration of Open5GS can mostly be used as-is.
There are a couple of modifications that have to be made to its configuration:

- Edit `/etc/open5gs/amf.yaml` with the correct N2 IP by setting the NGAP listen address to the VM IP. Furthermore, update the PLMNID and TAC as needed.
> PS: It is recommended to enable debug logs on the AMF

``` yaml
---
logger:
  file:
    path: /var/log/open5gs/amf.log
#  level: info   # fatal|error|warn|info(default)|debug|trace
  level: debug
  domain: amf
---
  ngap:
    server:
      - address: 10.55.5.4
---
  guami:
    - plmn_id:
        mcc: 001
        mnc: 01
      amf_id:
        region: 2
        set: 1
  tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 1
  plmn_support:
    - plmn_id:
        mcc: 001
        mnc: 01
      s_nssai:
        - sst: 1
```

- Edit `/etc/open5gs/upf.yaml` with the correct N3 IP by setting the GTP-U listen address to the VM IP.

``` yaml
---
  gtpu:
    server:
      - address: 10.55.5.4
---
```

- Edit `/etc/open5gs/nrf.yaml` with the correct PLMN IDs or comment these lines out entirely to allow roaming.

``` yaml
---
nrf:
  #serving:  # 5G roaming requires PLMN in NRF
  #  - plmn_id:
  #      mcc: 999
  #      mnc: 70
---
```

Restart the AMF and UPF:

``` bash
sudo systemctl restart open5gs-amfd
sudo systemctl restart open5gs-upfd
sudo systemctl restart open5gs-nrfd
```

## 3. Expose Open5gs GUI

To be able to reach the GUI from any IP address add these lines in `/etc/systemd/system/multi-user.target.wants/open5gs-webui.service` under the `[Service]` section.

```
[Service]
Environment=HOSTNAME=0.0.0.0
```

To apply the change:and restart the service 

```bash
sudo systemctl daemon-reload
sudo systemctl restart open5gs-webui.service
```

## 4. Provision UEs

This can be done via the GUI by Accessing `http://10.55.5.4:3000/` or by using command line as below:

``` bash
export SIM_IMSI="001010000006309"
export SIM_K="00112233445566778899aabbccddeeff"
export SIM_OPC="84d4c9c08b4f482861e3a9c6c35bc4d8"
open5gs-dbctl add $SIM_IMSI $SIM_K $SIM_OPC
```

## 5. Extra Steps for the Virtual Machines

**Changes In the CORE VM**

- Optimization changes for TCP throughput testing, edit `/etc/sysctl.conf` to add below lines:
```bash
# allow testing with buffers up to 64MB
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
# increase Linux autotuning TCP buffer limit to 32MB
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432
# change TCP congestion algorithm to BBR
net.ipv4.tcp_congestion_control = bbr
# recommended to use a 'fair queueing' qdisc
net.core.default_qdisc = fq
```
- To apply:
```bash
sudo sysctl --system 
```

## 6. More Information

More info can be found on:

- Internal Confluence page: [link](https://accelleran.atlassian.net/wiki/x/CQCXj)
- Open5gs website: [link](https://open5gs.org/open5gs/docs/guide/01-quickstart/)
- Open5gs github page: [link](https://github.com/open5gs/open5gs)