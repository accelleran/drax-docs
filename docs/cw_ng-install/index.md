# **Cell Wrapper Deployment**

> After installing drax [Steps](/drax-docs/drax_ng-install)

## 1. Prerequests

> Details can be found in [Granny Confluence Page](https://accelleran.atlassian.net/wiki/x/AQCXig)
- On the DRAX/CU/CW VM:
```bash
ssh-keygen -t ed25519 -f id_ed25519 -C cell-wrapper
kubectl create secret generic cw-ssh-key --from-file=private=id_ed25519 --from-file=public=id_ed25519.pub
```
  > Don't forget to add the above created public key to the DU and RU `~/.ssh/authorized_keys`

- On the DU machine:
```bash
sudo apt update && sudo apt install ifstat zip net-tools
sudo usermod -aG sudo $USER
printf "$USER ALL=(ALL) NOPASSWD:ALL\n" | sudo tee /etc/sudoers.d/$USER
```
- login to docker in the du machine
```bash
docker login
```

## 2. Deploying Cell Wrapper Controller

- **Please skip for default installation.** 
> This is only needed for deploying With Special Base DU/L1 Configuration.

- Edit the drax values file with the cellwrapper base config needed.

    > PS: the below example is to edit [Phluido](https://accelleran.atlassian.net/wiki/spaces/GS/pages/2522382337/2.2#Update.1) L1 config, but the same can be used for [Effnet](https://accelleran.atlassian.net/wiki/spaces/GS/pages/2522382337/2.2#Update) or [Nodeh](https://accelleran.atlassian.net/wiki/spaces/GS/pages/2522382337/2.2#Update.2)

```yaml
cell-wrapper:
  cw-inst:
    baseConfig:
      vendors:
        phluido:
        - file: "benetel_v0.7.l1.cfg"
          data: |-
            cccServerPort = 44444;
            cccInterfaceMode = 1;
            kpiOutputFormat = 2;
            maxPuschModOrder = 6;
            maxNumPdschLayers = 2;
            maxNumPuschLayers = 1;
            numWorkers = 8;
            targetRecvDelay_us = 1400;
            maxNumDlFronthaulPrbs = 144;
            pucchFormat0Threshold = 0.01;
            timingOffsetThreshold_nsec = 10000;
```

  - Update the DRAX deployed:
  ```bash
  helm upgrade --install drax accelleran-ng/drax --version 7.0.0-rc.6 --values drax-values.yaml --debug
  ``` 

- If there was already cell wrapper instanced deployed, run below to make sure the change takes effect.
    ```bash
    kubectl rollout restart deploy drax-cw-inst
    ```

## 3. Deploying Cell Wrapper Instances

- Create a values file for the cell, Please pay attention to the IPs used. (In this example the DU is `10.55.5.5` and the RU Fronthaul is `10.10.0.1` while the RU IP is `10.10.0.100`)

    > PS: The same yaml file can include multiple cells

```bash
tee cell-1-values.yaml <<EOF
global:
  config:
    enabled: true
    dus:
      - name: "du-1"
        install: |-
          <type>effnet</type>

          <image>accelleran/effnet-du-phluido</image>
          <version>2023-09-01-q2-patch-release-02</version>

          <ssh-connection-details xc:operation="create">
            <host>10.55.5.5</host>
            <username>ad</username>
          </ssh-connection-details>

          <l1 xc:operation="create">
            <image>accelleran/phluido-l1</image>
            <version>v8.7.4</version>

            <phluido-l1-config xc:operation="create">
              <license-key>651A-213B-96AB-0CA8-3E75-63F3-177D-D33F</license-key>
              <bbu-addr>10.10.0.1</bbu-addr>
            </phluido-l1-config>
          </l1>
        rus:
        - name: "ru-1"
          install: |-
            <type>benetel650</type>

            <ssh-connection-details xc:operation="create">
              <host>10.10.0.100</host>
              <username>root</username>
            </ssh-connection-details>

            <supported-frequency-band xc:operation="create">77</supported-frequency-band>

            <antenna-gain>0</antenna-gain>
            <maximum-power-capability>35</maximum-power-capability>
            <minimum-power-capability>15</minimum-power-capability>
EOF
```


- Deploy cell wrapper instance
    ```bash
    helm install cell-1 accelleran-ng/cell-wrapper-config --version 0.2.2 --values cell-1-values.yaml --debug
    ```

- Make sure all pods are operating normaly.
    ```bash
    watch kubectl get pods
    ```
