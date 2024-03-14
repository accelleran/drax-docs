# 7. Core Installation

If you already have a core you can skip this chapter.

> PS: From the [Example Network Diagram](/drax-docs/) the VM IP is 10.55.5.4.

> All below steps would be implemented on the CORE VM.


## 1. Install Open5GS


This [Install Script](/drax-docs/core-install/open5gs_install_script_from_apt.sh) can be used 

Otherwise, Please refer to [the Open5GS website](https://open5gs.org/open5gs/docs/guide/01-quickstart/) for information on how to install and configure the Open5GS core network on the virtual machine.

> NOTE : don't forget the ip forwarding section. If forgotten the UE connects with an exclemation mark in the triangle and has no internet connectivity.

## 2. Configure Open5GS

The default configuration of Open5GS can mostly be used as-is.
There are a couple of modifications that have to be made to its configuration:

- Edit `/etc/open5gs/amf.yaml` with the correct N2 IP by setting the NGAP listen address to the VM IP. Furthermore, update the PLMNID and TAC as needed.

``` yaml
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
Environment=PORT=3000
```

To apply the change:and restart the service 

```bash
sudo systemctl daemon-reload
sudo systemctl restart open5gs-webui.service
```

## 4. Provision UEs

This can be done via the GUI by Accessing `http://10.55.5.4:3000/` or by using command line as below:

``` bash
open5gs-dbctl add 001010000006309 00112233445566778899aabbccddeeff 84d4c9c08b4f482861e3a9c6c35bc4d8
```
