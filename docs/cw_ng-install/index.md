# **Cell Wrapper Deployment**

> After installing drax [Steps](/drax-docs/drax_ng-install)

## 1. Prerequests

- Can be found in [Granny Confluence Page](https://accelleran.atlassian.net/wiki/x/AQCXig)

## 2. Deploying Cell Wrapper Controller

- **Please skip for default installation.** 
> This is only needed for deploying With Special Base DU/L1 Configuration.

- Make sure DRAX was installed with cell-wrapper disabled.
    - This can be done by editing `drax-values.yaml` (change `cell-wrapper`: `enabled: false`)
    - Update the DRAX deployed:
  ```bash
  helm upgrade --install drax accelleran-ng/drax --version 7.0.0-rc.3 --values drax-values.yaml --debug
  ``` 

- Create a values file for the controller with the new base configuration.

    > PS: the below example is to edit Phluido L1 config, but the same file can be used for the other componenets

```bash
tee cw_ctrl_config.yaml <<EOF
bootstrap:
  redis:
    hostname: drax-redis-master

  nats:
    hostname: drax-nats

nats:
  enabled: false
redis:
  enabled: false


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

- Deploy cell wrapper controller
    ```bash
    helm install cw accelleran-ng/cell-wrapper --version 3.0.2  --values cw_ctrl_config.yaml --debug
    ```

- Make sure all pods are operating normaly.
    ```bash
    watch kubectl get pods
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

          <ssh-connection-details xc:operation="create">
            <host>10.55.5.5</host>
            <username>ad</username>
          </ssh-connection-details>

          <l1 xc:operation="create">
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
```


- Deploy cell wrapper instance
    ```bash
    helm install cell-1 accelleran-ng/cell-wrapper-config --version 0.2.1 --values cell-1-values.yaml --debug
    ```

- Make sure all pods are operating normaly.
    ```bash
    watch kubectl get pods
    ```