# 7. Effnet-Phluido-Benetel Preparation

## 1. Effnet-Phluido Changes

### 1.1. Load DU Image

> This section is only needed when cell wrapper is not used.

- Copy the file containing the image to the server. (example file accelleran-du-phluido-2024-01-31-q3-patch-release-01-8.7.4.zip)
- Load image
```bash
sudo apt install unzip
unzip accelleran-du-phluido-2024-01-31-q3-patch-release-01-8.7.4.zip
cd accelleran-du-phluido-2024-01-31-q3-patch-release-01-8.7.4
bzcat gnb_du_main_phluido-2024-01-31-q3-patch-release-01-8.7.4.tar.bz2 | docker image load
```
- Validate that the docker image was loaded and take note of the image tag
```bash
docker images
```

### 1.2. Load DU License

- Make sure a yubikey is inserted and then run below:
```bash
mkdir -p pcscd 
tee pcscd/Dockerfile.pcscd <<EOF
FROM ubuntu:22.04

RUN \
set -xe && \
apt-get update && \
DEBIAN_FRONTEND="noninteractive" apt-get install -y \
    pcscd

# Cleanup
RUN \
set -xe && \
apt-get clean && \
rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

ENTRYPOINT ["/usr/sbin/pcscd", "--foreground"]
EOF
docker build --rm -t pcscd_yubikey - <pcscd/Dockerfile.pcscd
docker run --restart always -id --privileged --name pcscd_yubikey_c -v /run/pcscd:/run/pcscd pcscd_yubikey
```
- If a new license is to be loaded, Use the activation file provided by effnet to run below:
```bash
unzip effnet-license-activation-2023-06-29_01.zip
cd effnet-license-activation-2023-06-29_01
bunzip2 --stdout effnet-license-activation-2023-06-29.tar.bz2 | docker load
docker run -it --rm -v /var/run/pcscd:/var/run/pcscd effnet/license-activation-2023-06-29
```


### 1.3. Load UL1 Image

> This section is only needed when cell wrapper is not used.

- Copy the binary of the UL1 into the server. (example file for v8.7.4 was named PhluidoUL1_NR_v8_7_4)
- Prepare files. (Use the date of the installation) and then load image
```bash
mkdir Phluido5GL1_v8.7.4
cd Phluido5GL1_v8.7.4
mv ~/PhluidoUL1_NR_v8_7_4 PhluidoUL1_NR
echo "2023-06-12, 12:00:00" > L1_NR_copyright
tee Dockerfile.l1 <<EOF
FROM ubuntu:20.04

COPY PhluidoUL1_NR /
COPY L1_NR_copyright /root/.Phluido/L1_NR_copyright

ENTRYPOINT ["/PhluidoUL1_NR"]
EOF
cd ..
docker build -f Phluido5GL1_v8.7.4/Dockerfile.l1 -t phluido_l1:v8.7.4 Phluido5GL1_v8.7.4
```
- Validate that the docker image was loaded and take note of the image tag
```bash
docker images
```

## 2. Benetel Changes

### 2.1. Set DU MAC Address

- Check the Fronthaul interface MAC address on the DU server side.
```bash
ifconfig enp1s0f1
```

- ssh into the RU and set the DU MAC with EEPROM. (assuming the mac address was `7c:c2:55:69:f8:eb`)
```bash
echo -n "0-0057" > /sys/bus/i2c/devices/0-0057/driver/unbind
registercontrol -w 0xC036B -x 0x88000088
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1a:0x01:0x7c
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1b:0x01:0xc2
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1c:0x01:0x55
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1d:0x01:0x69
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1e:0x01:0xf8
eeprog_cp60 -f -x -16 /dev/i2c-0 0x57 -w 0x1f:0x01:0xeb
registercontrol -w 0xC036B -x 0x88000488
```
- Verify by running:
```bash
eeprog_cp60 -q -f -x -16 /dev/i2c-0 0x57 -x -r 26:6
```
- Reboot the RU to apply the change

> # Back to [Server Preparation](/drax-docs/machine-prep/)