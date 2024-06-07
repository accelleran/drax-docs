# Cell Wrapper Deployment

This can only be done after installing drax as shown [here](/drax-docs/drax/8.0.0/)

## 1. Prerequests

> Details can be found in [Granny Confluence Page](https://accelleran.atlassian.net/wiki/x/AQCXig)

**Generate SSH keys**

- To generate ssh key pair and create a K8s secret with them to be used by the cell wrapper:
```bash
ssh-keygen -t ed25519 -f id_ed25519 -C cell-wrapper
kubectl create secret generic cw-ssh-key --from-file=private=id_ed25519 --from-file=public=id_ed25519.pub
```

- Add the public key created `id_ed25519.pub` to the DU server and RUs to be used in `~/.ssh/authorized_keys`

**Steps needed with RAN1 and RAN3**

- On the DU machine:
    - Allow running sudo commands without password
```bash
sudo apt update && sudo apt install ifstat zip net-tools
sudo usermod -aG sudo $USER
printf "$USER ALL=(ALL) NOPASSWD:ALL\n" | sudo tee /etc/sudoers.d/$USER
```
    - Login to docker to allow downloaded needed DU images
```bash
docker login
```

## 2. Deploying Cell Wrapper Controller

**Please skip for default installation.** 
> This is only needed for deploying With Special Base DU/L1 Configuration.

- create a values yaml file with the cellwrapper base config needed.

```bash
tee drax-values-extra-changes.yaml <<EOF
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
EOF
```
  > **Note:** The above example is to edit Phluido UL1 L1 config, but the same can be used for the other compoenets. Details can be found in [Cell Wrapper Confluence Page](https://accelleran.atlassian.net/wiki/x/AQB_rQ)

  - Update the DRAX deployed:
  ```bash
  helm upgrade --install drax accelleran/drax --reuse-values --values drax-values-extra-changes.yaml
  ``` 

- If there was already cell wrapper instanced deployed, run below to make sure the change takes effect.
    ```bash
    kubectl rollout restart deploy drax-cw-inst
    ```

## 3. Deploying Cell Wrapper Instances

- Create a values file for the cell, Please pay attention to the details used and edit them according to the system. (IP/MAC addresses, VLAN, RU Information, ..etc)

    - RAN1 example: [cell-1-values.yaml](cell-values_effnet_phluido_benetel.yaml)
    - RAN2 example: [cell-1-values.yaml](cell-values_nodeh_tnw.yaml)
    - RAN3 example: [cell-1-values.yaml](cell-values_accellerandu_benetel.yaml) 

> PS: The same yaml file can include multiple cells from different vendors. [More details](https://accelleran.atlassian.net/wiki/spaces/GS/pages/2910715905/4.0)


- Deploy cell wrapper instance
    ```bash
    helm install cell-1 accelleran/cell-wrapper-config --version 0.3.0 --values cell-1-values.yaml --debug
    ```

- Make sure all pods are operating normaly.
    ```bash
    watch kubectl get pods
    ```
