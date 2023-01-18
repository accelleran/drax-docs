## EFFNET DU INSTALLATION

This section is dedicated to users who inted to update their licensed Effnet DU only. The DU will be installed in a Docker container that run on metal 
on the host machine. As mentioned in the introduction, a separate Virtual Machine will host the RIC and the CU and their relative pods will be handled
by Kubernetes inside that VM. Here we focus on the steps to update the DU and bring it back up and running.

We don't modify the parameters and the configuration in this section and we assume this is done previously

#### licenses and files needed
* accelleran-du-phluido-%Y-%m-%d-release.zip
* effnet-license-activation-%Y-%m-%d.zip 

For the license activation file we indicate the generic format yyyy_mm_dd as the file name may vary from case to case, your Accelleran point of contact 
will make sure you receive the correct license activation archive file which will have a certain timestamp on it, example effnet-license-activation-2021-12-16.zip

To check if the server can see the key do (in this example Device004 is your key): 
``` bash
lsusb
~$ lsusb
Bus 002 Device 002: ID 8087:8002 Intel Corp. 
Bus 002 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 001 Device 002: ID 8087:800a Intel Corp. 
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 004 Device 003: ID 2500:0020 Ettus Research LLC USRP B200
Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
**Bus 003 Device 004: ID 1050:0407 Yubico.com Yubikey 4 OTP+U2F+CCID**
Bus 003 Device 029: ID 2a70:9024 OnePlus AC2003
Bus 003 Device 006: ID 413c:a001 Dell Computer Corp. Hub
Bus 003 Device 016: ID 20ce:0023 Minicircuits Mini-Circuits
Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```
Then you can find the serial number (yubikey-manager needed, install if it's not already):

``` bash
sudo apt install yubikey-manager
```
``` bash
ykman list --serials
#13134288
```
#### Effnet License: Stop the PCSCD Docker Daemon

The DU software needs access to a YubiKey that contains its license.
The license in the YubiKey is shared by the PCSCD daemon, which itself can run in a Docker container to satisfy OS dependencies. the first thing to do is 
to stop the daemon and verify there is no Docker Container running any DU instance (the cell wrapper has been previously disabed or uninstalled) 

 rm -rf effnet-license-activation-2023-01-13

 docker container ls --filter name=pcscd_yubikey_c
 1853  docker ps
 1854  docker kill 769ff29e51d3
 1855  docker ps
 1856  docker build --rm -t pcscd_yubikey - <pcscd/Dockerfile.pcscd
 1857  cd
 1858  docker build --rm -t pcscd_yubikey - <pcscd/Dockerfile.pcscd
 1859  docker run --restart always -id --privileged --name pcscd_yubikey_c -v /run/pcscd:/run/pcscd pcscd_yubikey




 1906  docker container ls --filter name=pcscd_yubikey_c


1929  docker image ls | grep effnet
 1930  docker image rm e0e2f6c480f1
 1931  docker container ls | grep effnet

rm -rf effnet-license-activation-2023-01-13
 1958  docker image ls | grep effnet
 1959  unzip effnet-license-activation-2023-01-16.zip 
 1960  cd effnet-license-activation-2023-01-16/
 1961  history
 1962  docker container ls --filter name=pcscd_yubikey_c
 1963  ykman list -s
 1964  docker run -it -v /var/run/pcscd:/var/run/pcscd effnet/license-activation-2023-01-16
 1965  bunzip2 --stdout effnet-license-activation-2023-01-16.tar.bz2 | docker load
 1966  docker run -it -v /var/run/pcscd:/var/run/pcscd effnet/license-activation-2023-01-16
