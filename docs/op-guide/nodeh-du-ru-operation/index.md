# Split 2 Cell Operation

This section is exclusively applicable to the user/customer that intends to use the Node-H DU with Askey RU or T&W RU with our Accellleran 5G end to end solution, if you do not have such radio end the informations included in this section may be misleading and bring to undefined error scenarios. Please contact Accelleran if your Radio End is not included in any section of this user guide.

Please note, on this system release 2022.4.0 the cell wrapper is yet to be intgerated with the split 2 solution. So cell operation and configuration must be done from the DU/RU unit itself. This won't be the same with the next system release.

## 1. Start/Stop Cell

ssh into the DU/RU unit and run below command to start the cell.
```bash
systemctl start nodeh-5g 
```

To stop the cell:
```bash
systemctl stop nodeh-5g 
```

> Because of a bug in the L1 of this release, To start the cell again, a reboot maybe necessary on the unit. So just run ```reboot``` on the unit and then ssh into it again and run ```systemctl start nodeh-5g```. The unit usually boot up very fast.

## 2. Simple Cell Configuration

The cell configuration file is located in ```/var/lib/nodeh/data/fap_config_si.json```.  Simply changing the parmeter value in there and restarting the cell will get the new parameter value to take effect.

### 2.1. Frequency Modification

Simply use the center frequency ARFCN, and make sure it is within the n78 band e.g: 
```bash
"General":{"ChannelNrArfcn": 651648}
```

### 2.2. Bandwidth Modification

The unit support up to 100MHz. Testing was done on 40MHz and 100MHz.

- For 40MHz:
```bash
"General":{"ChannelBwRb": 106},
"MAC":{"BwpDl":{"1":{"Nrb": 106}},"BwpUl":{"1":{"Nrb": 106}}}
```
- For 100MHz:
```bash
"General":{"ChannelBwRb": 273},
"MAC":{"BwpDl":{"1":{"Nrb": 273}},"BwpUl":{"1":{"Nrb": 273}}}
```


### 2.3. RU Synchrnoization Source

The unit support three modes:

- GPS: 
```bash
"General":{"SyncSource": "GPS"}
```
- PTP:
```bash
"General":{"SyncSource": "PTP"}
```
- Free running:
```bash
"General":{"SyncSource": "FreeRunning"}
```

### 2.4. TX Power

The unit supports up to 24dBm. This parameter is a 10 multiple of the Tx power. e.g (18dBm):
```bash
"General":{"TxPowerPerPathDBmx10": "180"}
```