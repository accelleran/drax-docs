## EFFNET DU UPDATE

This section is dedicated to users who inted to update their licensed Effnet DU only. The DU will be installed in a Docker container that run on metal 
on the host machine. As mentioned in the introduction, a separate Virtual Machine will host the RIC and the CU and their relative pods will be handled
by Kubernetes inside that VM. Here we focus on the steps to update the DU and bring it back up and running.

We don't modify the parameters and the configuration in this section and we assume this is done previously

#### licenses and files needed
* accelleran-du-phluido-%Y-%m-%d-release.zip
* effnet-license-activation-%Y-%m-%d.zip 

For the license activation file we indicate the generic format yyyy_mm_dd as the file name may vary from case to case, at this point your Accelleran point of contact already made sure you received the correct license activation archive file which will have a certain timestamp on it, example effnet-license-activation-2021-12-16.zip

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
#### Effnet License: Stop the running containers and the Cell Wrapper 

The first thing to do is to stop the running containers and prevent the Cell Wrapper from continuisly attempting to restart the components. For the Cell Wrapper simply login to your machine where the RIC is running and do:

``` bash
 
```
Regarding the rest, the DU software needs access to a YubiKey that contains its license.The license in the YubiKey is shared by the PCSCD daemon, which itself can run in a Docker container to satisfy OS dependencies. the first thing to do is to stop the daemon and verify there is no Docker Container running any DU instance (the cell wrapper has been previously disabed or uninstalled) 

Optional step: Remove the existing installation directory and its zip archive:

``` bash
rm accelleran-du-phluido-yyyy-mm-dd-version.zip 
rm -rf accelleran-du-phluido-yyyy-mm-dd-version
```
Check and kill the relevant running containers:

``` bash
 docker container ls --filter name=pcscd_yubikey_c
 CONTAINER ID   IMAGE           COMMAND                  CREATED        STATUS      PORTS     NAMES
8f6cd6af4333   pcscd_yubikey   "/usr/sbin/pcscd --f…"   4 months ago   Up 3 days             pcscd_yubikey_c
docker kill 8f6cd6af4333 (CONTAINER_ID)

docker ps | grep effnet 
docker ps | grep phluido
516a9be070d3   gnb_du_main_phluido:yyyy-mm-dd-version  "/bin/sh -c 'sleep 2…"   30 seconds ago   Up 30 seconds             gnb_du_main_phluido
bcaf36e5834b   phluido_l1:v8.7.1                               "/PhluidoUL1_NR /con…"   30 seconds ago   Up 30 seconds             phluido_l1
 
 docker kill 516a9be070d3 bcaf36e5834b (you better kill L1 now as well)
 
```
Verify one last time that docker ps will return no running processes and remove the DU docker image:

``` bash
 
docker image ls | grep gnb_du
gnb_du_main_phluido           yyyy-mm-dd-version                          f7d7f75d7294   2 months ago   137MB
docker image rm f7d7f75d7294
Untagged: gnb_du_main_phluido:yyyy-mm-dd-version
Deleted: sha256:f65f9f66f7227b47b9205a30171822bc5e0affecce2ed90297efa74728cbceb7
Deleted: sha256:e561bbd172ba022fb1e2544f890b6db10ecb6817f3fb0c2f62f7db3e2edecc30
Deleted: sha256:b33bd2a555a1ad76656e47e3383026fda2029e2f93062f40cf5af2eff399f691
Deleted: sha256:b3cba33e6be01e7c59b44298fb6da156644cb9d5646a1158ce48cd6294af155f
Deleted: sha256:bf2537d1f5f6f7b597e313b86695f5d7cbeb11b2753dafbb879c596b35e993eb
Deleted: sha256:0770b7f116f8627ec336a62e65a1f79e344df7ae721eb3e06e11edca85d3d1e7
Deleted: sha256:476e931831a5b24b95ff7587cca09bde9d1d7c0329fbc44ac64793b28fb809d0
Deleted: sha256:9f32931c9d28f10104a8eb1330954ba90e76d92b02c5256521ba864feec14009

```
#### Effnet License: Load the new image and restart PCSCD license daemon and the Cell Wrapper 

Now you can proceed on loading the new image. Unzip the effnet software bundle, and execute a docker load as follows:
``` bash
 unzip accelleran-du-phluido-yyyy-mm-dd-version.zip 
 bzcat accelleran-du-phluido-yyyy-mm-dd-version/gnb_du_main_phluido-yyyy-mm-dd-version.tar.bz2  | docker image load
```
Don't forget to start the license daemon again:
``` bash
docker build --rm -t pcscd_yubikey - <pcscd/Dockerfile.pcscd
docker run --restart always -id --privileged --name pcscd_yubikey_c -v /run/pcscd:/run/pcscd pcscd_yubikey
docker container ls --filter name=pcscd_yubikey_c
```
Verify that the docker image has been loaded and the license daemon is running again:
``` bash
docker image ls | grep gnb_du
gnb_du_main_phluido           yyyy-mm-dd-version                           b8c7c94d8215   1 minute ago   87MB

docker container ls --filter name=pcscd_yubikey_c
CONTAINER ID   IMAGE           COMMAND                  CREATED        STATUS      PORTS     NAMES
8f6cd6af4333   pcscd_yubikey   "/usr/sbin/pcscd --f…"   4 months ago   Up 1 minute             pcscd_yubikey_c
```
Now login to your RIC VM, locate the directory where your Cell Wrapper yaml configuration file is (typically named "cw.yml") and redeploy it:

``` bash
helm install cw acc-helm/cw-cell-wrapper --values cw.yaml
```

If you have done your job correctly, wait for a few minutes and observe your system go back to life and your Cell will go back on air, this can be seen of course in your Dashboard:





``` bash

```


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
