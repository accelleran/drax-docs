# Cell Wrapper Deployment

This can only be done after installing drax as shown [here](/drax-docs/drax/8.0.0/)

> PS: All the following steps and sections won't be needed in case of using ansible. Guide available in [5G Integration Repo](https://github.com/accelleran/5g-integration/tree/main/utilities/install_tools/ansible)


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

## 2. Deploying Cell Wrapper Instances

- Create a values file for the cell, Please pay attention to the details used and edit them according to the system. (IP/MAC addresses, VLAN, RU Information, ..etc)

    - RAN3 (accDU/benetelRU) example: [cell-1-values.yaml](cell-values_ran3.yaml) 

- Make sure to edit `extra-args` and `extra-config` with the detailed CPU allocation based on the cell as below:
<p align="center">
  <img src="/drax-docs/SystemRelease/2024.2.0/prep_machine/cpu_allocation.png">
</p>


> For RAN2 (nodehDU) example: [cell-1-values.yaml](cell-values_ran2.yaml)

- Deploy cell wrapper instance
    ```bash
    helm install cell-1 accelleran/cell-wrapper-config --version 0.5.1 --values cell-1-values.yaml --debug
    ```

- Make sure all pods are operating normaly.
    ```bash
    watch kubectl get pods
    ```

## 3. Uninstalling CellWrapper Instances

- Undeploy using helm (e.g. cell-1 deployed above) 
```bash
helm uninstall cell-1
```
