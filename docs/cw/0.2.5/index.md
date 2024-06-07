# Cell Wrapper Deployment

This can only be done after installing drax as shown [here](/drax-docs/drax/7.1.0/)

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

    > PS: the below example is to edit[Phluido](https://accelleran.atlassian.net/wiki/spaces/GS/pages/2910715905/4.0#Phluido-L1) L1 config, but the same can be used for [Effnet](https://accelleran.atlassian.net/wiki/spaces/GS/pages/2910715905/4.0#config.du.json), [Nodeh](https://accelleran.atlassian.net/wiki/spaces/GS/pages/2522382337/2.2#Update.2), or [accDU](https://accelleran.atlassian.net/wiki/spaces/GS/pages/2910715905/4.0#Templates) DU config, 

```yaml
cell-wrapper:
  cw-inst:
    baseConfig:
      vendors:
        phluido:
        - file: "config.l1.cfg"
          data: |-
            LicenseKey = "{{ du.phluido.license }}";
            bbuFronthaulServerAddr = "{{ du.ofh.ipAddress }}";
            bbuFronthaulServerPort = {{ du.ofh.port }};
            rruFronthaulClientAddr = "{{ at(at(rus, at(at(ran.servedCells, 0).sectorCarriers, 0).ruName), "ofh").ipAddress }}";
            rruFronthaulClientPort = {{ at(at(rus, at(at(ran.servedCells, 0).sectorCarriers, 0).ruName), "ofh").port }};
            cccServerPort = 44444;
            cccInterfaceMode = 1;
            maxPuschModOrder = 6;
            maxNumPdschLayers = 2;
            maxNumPuschLayers = 1;
            numWorkers = 8
            targetRecvDelay_us = 1479;
            maxNumDlFronthaulPrbs = 144;
            fronthaulStreamingDelay_us = 7000;
            kpiOutputFormat = 2;
```

  - Update the DRAX deployed:
  ```bash
  helm upgrade --install drax accelleran/drax --version <RIC_VERSION> --values drax-values.yaml --debug
  ``` 

- If there was already cell wrapper instanced deployed, run below to make sure the change takes effect.
    ```bash
    kubectl rollout restart deploy drax-cw-inst
    ```

## 3. Deploying Cell Wrapper Instances

- Create a values file for the cell, Please pay attention to the IPs used. (In this example the DU is `10.55.5.5` and the RU Fronthaul is `10.10.0.1` while the RU IP is `10.10.0.100`). [More details](https://accelleran.atlassian.net/wiki/spaces/GS/pages/2910715905/4.0)

    > PS: Below file is for Effnet/Phluido/CATB. The same yaml file can include multiple cells from different vendors

```bash
tee cell-1-values.yaml <<EOF
global:
  # nodeSelector:
  #   drax.accelleran.com/schedule: "true"

  config:
    enabled: true
    dus:
      - name: "du-1"
        install: |-
          <type>effnet</type>

          <version>2024-01-31-q3-patch-release-01-8.9.3</version>
          <extra-args>--cpuset-cpus=8,9,10,11,24,25,26,27</extra-args>

          <ssh-connection-details xc:operation="create">
            <host>10.55.5.5</host>
            <username>ad</username>
          </ssh-connection-details>

          <e2-config xc:operation="replace">
            <enable>true</enable>
            <host>10.55.5.37</host>
            <port>38482</port>
          </e2-config>

          <metrics xc:operation="replace">
              <enable>true</enable>
          </metrics>

          <ofh-interface xc:operation="replace">
            <ip-address>10.10.0.1</ip-address>
            <port>44000</port>
            <mac-address>7c:c2:55:7b:08:79</mac-address>
          </ofh-interface>

          <phluido xc:operation="replace">
            <version>v8.12.1</version>
            <extra-args>--cpuset-cpus=8,9,10,11,24,25,26,27</extra-args>
            <license-key>651A-213B-96AB-0CA8-3E75-63F3-177D-D33F</license-key>
          </phluido>

          <netconf xc:operation="replace">
              <enable>true</enable>
          </netconf>

          <netconf-connection-details xc:operation="replace">
              <host>10.55.5.5</host>
              <port>830</port>
              <username>effnet</username>
              <password>effnet</password>
          </netconf-connection-details>

        internal: |-
          <configuration xc:operation="replace">
            <enable>true</enable>
          </configuration>
          <health-check xc:operation="replace">
            <traffic-throughput xc:operation="replace">
                <enable>true</enable>
            </traffic-throughput>
          </health-check>
        rus:
        - name: "ru-1"
          install: |-
            <type>benetel</type>

            <ssh-connection-details xc:operation="create">
              <host>10.10.0.100</host>
              <username>root</username>
            </ssh-connection-details>

            <ofh-interface xc:operation="replace">
              <ip-address>10.10.0.100</ip-address>
              <port>44000</port>
            </ofh-interface>

            <nof-antennas-dl>2</nof-antennas-dl>
            <nof-antennas-ul>1</nof-antennas-ul>

            <serial-number>06502200419</serial-number>
            <supported-frequency-band xc:operation="create">78</supported-frequency-band>
            <supported-frequency-band xc:operation="create">77</supported-frequency-band>

            <antenna-gain>0</antenna-gain>
            <maximum-power-capability>35</maximum-power-capability>
            <minimum-power-capability>15</minimum-power-capability>
EOF
```


- Deploy cell wrapper instance
    ```bash
    helm install cell-1 accelleran/cell-wrapper-config --version 0.2.5 --values cell-1-values.yaml --debug
    ```

- Make sure all pods are operating normaly.
    ```bash
    watch kubectl get pods
    ```
