# Extra Info

## 1. Related to the Server Preperation

### 1.1. Unsupported SFP+ module type was detected
- Use information on this [link](https://www.serveradminz.com/blog/unsupported-sfp-linux/)

### 1.2. Virtual Functions Can't Be Used

- For example in cases where SR-IOV is not supported.
- Bridge Interface would need to be created on the server and then add NIC interfaces on the CU and CORE VMs to use it.

```bash
sudo apt install bridge-utils
sudo brctl addbr br0
```
- Assuming the baremetal server interface is called enp2s0f1, Adapt the server netplan to use a bridge and apply
```bash
network:
  ethernets:
    enp2s0f1:
      dhcp4: false
      optional: true

  bridges:
    br0:
      addresses: 
      - 10.55.5.2/24
      - 10.55.5.5/24
      gateway4: <>
      nameservers: 
        addresses: [<>]
      interfaces:
        - enp2s0f1
```
- With virt-manager GUI edit the VM: `Add Hardware` -> `Network`.
<p align="center">
  <img src="bridge_interface.png">
</p>

