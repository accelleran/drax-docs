# RIC and CU Installation

## Introduction

This document as part of the Accelleran Interna Installation User Guide contains only the minimal set of information to achieve a default installation of dRAX, with some assumptions made such as software and hardware prerequisites as well as Network Configuration. The configuration is instead part of the other [Operational User Guide](../../op-guide/) 

The first section gives a detailed overview on hardware, software and other requirements that are considered as default prerequisites to install and operate a dRAX installation.

The second section describes all of the steps needed to deploy new software version of Accelleran's RIC for the first time, using provided Helm charts.
This section is split into multiple subsections, including one for the installation of the RIC base, one for the 4G components, and one for the 5G components.
For a first time installation, it is important to verify of course the SW and HW prerequisites presented in this document before proceeding further.

## Software and Hardware Prerequisites

The assumption made in this User Guide is that the typical user is familiar with Server installations, VMs and VNFs

Also, as mentioned in the [Overview](../index.md) section of this document, it is assumed that the VM is already created with a *NODE_IP* address in the same subnet of the Server (*SERVER_IP*) and a linux bridge *br0*.


### Software Requirements have been installed in previous chapter.

1. Linux Ubuntu Server 20.04 LTS
2. Docker (recommended version 19.03, check the latest compatible version with Kubernetes)
3. Permanently disabled swap
4. Kubernetes 1.13 or later till 1.20 (1.21 is currently unsupported)

### Other Requirements

1. RIC License license.crt
2. enabled DockerHub account
3. EPC/5GC must be routable without NAT from RIC (and E1000 DUs in case of 4G)
4. From Accelleran you will need access to the Dockerhub repository
    * please create your account with user, password and email from dockerub
5. Internet access on the server    

### 4G Specific requirements:

1. A DHCP server must be available on the subnet where the E1000 DUs will be installed
2. E1000 DUs must be in the same subnet as Kubernetes' advertised address (otherwise refer to [Appendix: E1000 on separate subnet](#appendix-drax-and-accelleran-e1000s-on-different-subnets))

### Limitations : 
1. When using a graphical interface, make sure it will not go to sleep or to standby. 

## Installation

### Introduction

This section explains how to install dRAX for the very first time in its default configuration.
Assuming that the Customer has already verified all the prerequisites described in the previous Section 4.
If you already have dRAX and are only updating it, please refer to the [section on updating an existing installation](#updating-existing-installations).

dRAX consists of multiple components:

* RIC and Dashboard (required)
* 4G components based on Accelleran's E1000 DU and 4G CU
* 5G components based on Accelleran's 5G SA CU

You should decide at this point which of these components you intend to install during this process as it will impact many of the steps.

### Plan your deployment

We recommend storing all files created during this installation process inside of a dedicated folder, e.g. _dRAX-yyyymmdd_, so that they are clearly available for when you next update the installation.
These files could also be committed to version control, or backed up to the cloud.

#### Plan parameters

Please determine the following parameters for your setup - these will be used during the installation process.

| Description                                   | Parameter |
| --------------------------------------------- | --------- |
| Kubernetes advertise IP address               | $NODE_IP  |
| The interface where Kubernetes is advertising | $NODE_INT |

#### Prepare License and Certificate

In order to run Accelleran's dRAX software, a License file is required - this license file will be named **license.crt** and will be used in a later step.

4G Only : If you intend to deploy the 4G aspects of dRAX (together with Accelleran's E1000 4G DUs), you will also need to prepare a certificate to ensure secure communication between the various components.
Please refer to [the Appendix on creating certificates](#appendix-drax-provisioner-keys-and-certificates-generation).
This will also need to be validated and signed by Accelleran's customer support team, so please do this in advance of attempting the installation.

#### Namespaces (Optional)

The definition of namespaces is optional and should be avoided if there is no specific need to define them in order to separate the pods and their visibility, as it brings in a certain complexity in the installation, the creation of secrets, keys, and the execution of kubernetes commands that is worth being considered upfront. At the preference of the customer, additional Kubernetes namespaces may be used for the various components which will be installed during this process.
Kubernetes namespaces should be all lowercase letters and can include the "-" sign.

As mentioned, extra steps or flags must be used with most of the commands that follow. The following table describes the different “blocks” of components, and for each, a distinct namespace that may be used, as well as the default namespace where these components will be installed.

| Description          | Parameter   | Default Namespace |
| -------------------- | ----------- | ----------------- |
| Core dRAX components | `$NS_DRAX`  | default           |
| dRAX 4G CUs          | `$NS_4G_CU` | `$NS_DRAX`        |
| dRAX 5G CUs          | `$NS_5G_CU` | default           |

The Default Namespace column sometimes contains another Namespace placeholder, e.g. the NS_4G_CU default is $NS_DRAX - this means that the default behaviour is to run the CUs in the $NS_DRAX namespace, but it can be overridden.
If neither $NS_DRAX nor $NS_4G_CU is specified, the CU will run in the "default" namespace.

### Install dRAX for the first time 

#### install helm
if helm is not yet installed install it this way

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
```
```
chmod 700 get_helm.sh
```
```
./get_helm.sh
```

#### Add Accelleran Helm Chart Repo

Use the helm command:

``` bash
helm repo add acc-helm https://accelleran.github.io/helm-charts/
```

#### Update Helm Charts

To update to our latest version, we need to update the Helm charts:

``` bash
helm repo update
```


#### Create namespace(s) for dRAX (optional)

If you choose to use dedicated namespaces for dRAX, please create them before the installation process.

```
export NS_DRAX=$NS_DRAX
``` 

``` bash
kubectl create namespace $NS_DRAX
```

This needs to be repeated for each namespace that you wish to use for dRAX, either for the RIC, 4G or 5G components

!!! warning
    If you choose to use specific namespaces, special care must be used throughout the remaining steps when executing the kubectl commands.
    For each one, it is important to specify the appropriate namespace using the -n option, example:

``` bash
kubectl get pods -n $NS_DRAX
```

#### Configure DockerHub credentials in Kubernetes

If you have previously obtained (from the Customer Support) access to Accelleran Dockerhub repository, you can now proceed to create a secret named `accelleran-secret` with your DockerHub credentials, specifically using the kubectl command (do not forget the `-n <namespace>` option if you selected different namespaces previously):

``` bash
kubectl create secret docker-registry accelleran-secret --docker-server=docker.io --docker-username=DOCKER_USER --docker-password=DOCKER_PASS --docker-email=DOCKER_EMAIL
```

This needs to be repeated for each namespace that you created previously, specifying each namespace one time using the -n flag.

#### Configure License in Kubernetes

Create a secret named `accelleran-license` using the previously provided License file.
The name of this secret is critical - this name is used in our Helm charts to access the License file.

``` bash
kubectl create secret generic accelleran-license --from-file=license.crt
```
> Note: if you need for any reason to use a license file with a different (ex. myfile) name the command is a bit more cumbersome:
>
> ``` bash
> kubectl create secret generic accelleran-license --from-file=license.crt=myfile
> ```

**This needs to be repeated for each namespace that you created previously, specifying each namespace one time using the -n flag**

### Install dRAX RIC and Dashboard

#### Prepare RIC values configuration file

We first have to prepare the Helm values configuration file for the dRAX RIC and Dashboard Helm chart.
To do so, we first retrieve the default values file from the Helm chart repository and save it to a file named `ric-values.yaml`.
the  this with the following command:

``` bash
curl https://raw.githubusercontent.com/accelleran/helm-charts/6.1.0/ric/simple-values/simple-values.yaml  > ric-values.yaml
```

Next, edit the newly created `ric-values.yaml` file.
Find the following fields and edit them according to your setup.
We use parameters from the [Plan your deployment](#plan-parameters) section, such as 
* `NODE_IP`, to show what should be filled in

In the example below we disabled 4G assuming we don't install the 4G component.

``` yaml
global:
    kubeIp: NODE_IP
    enable4G: false
    # Enable the components that you intend to install
    # Note that these must also be supported by the License you have
```

#### Enabling 5G components

If you plan to install the 5G components (and you have the license to support this), you need to make a few other adjustments to the `ric-values.yaml` file:
Make sure the Pool of Load Balancer IP addresses is in the same subnet of the NODE_IP Kubernetes advertised IP address and also that those addresses are free in the server and will not be taken for other VMs or interfaces eg: NODE_IP=10.10.10.20 RANGE=10.10.10.110-10.10.10.120. Make also sure that you allocate a large enough range of addresses depending on your deployment topology

``` yml
global:
    enable5G: true
acc-5g-infrastructure:
    metallb:
        configInline:
            address-pools:
                - name: default
                  protocol: layer2
                  # IP pool used for E1, F1 and GTP interfaces when exposed outside of Kubernetes
                  addresses:
                      - RANGE
```

> NOTE : The IP pool which is selected here will be used by [MetalLB](https://metallb.universe.tf/), which we use to expose the E1, F1, and GTP interfaces to the
> external O-RAN components, such as the DU, and the 5GCore. In other words, the CUCP E1, CUCP F1 and the CUUP GTP IP addresses will be taken from the specifed pool:

``` bash
$ kubectl get services
#NAME                                             TYPE           CLUSTER-IP       EXTERNAL-IP     PORT> S)                                                                                     AGE
 #acc-5g-cu-cp-cucp-1-sctp-e1                      LoadBalancer   10.107.230.196   10.10.10.120  38462:31859/SCTP                                                                            3h35m
 #acc-5g-cu-cp-cucp-1-sctp-f1                      LoadBalancer   10.99.246.255    10.10.10.121  38472:30306/SCTP                                                                            3h35m
 #acc-5g-cu-up-cuup-1-cu-up-gtp-0                  LoadBalancer   10.104.129.111   10.10.10.122  2152:30176/UDP                                                                              3h34m
 #acc-5g-cu-up-cuup-1-cu-up-gtp-1                  LoadBalancer   10.110.90.45     10.10.10.123  2152:30816/UDP                                                                              3h34m
```

> NOTE : MetalLB works by handling ARP requests for these addresses, so the external components need to be in the same L2 subnet in order to access these interfaces.

 
#### Enabling 4G components

4G Only : when you don't need 4G you can skip and move on to chapter [Install the dRAX RIC and Dashboard](#install-the-drax-ricand-dashboard) where the RIC is actually being installed.

#### 4G : Prepare keys and certificates for the dRAX Provisioner

The working assumption is that keys and certificates for the dRAX Provisioner have been created by the Accelleran Support Team, however, for a more detailed guide, please check the [Appendix: dRAX Provisioner - Keys and Certificates Generation](#appendix-drax-provisioner-keys-and-certificates-generation) of this document.

#### 4G : Create configMaps for the dRAX Provisioner

We now need to store the previously created keys and certificates as configMaps in Kubernetes, so that they can be used by the dRAX Provisioner:

``` bash
kubectl create configmap -n $NS_DRAX_4G prov-server-key --from-file=server.key
kubectl create configmap -n $NS_DRAX_4G prov-server-crt --from-file=server.crt
kubectl create configmap -n $NS_DRAX_4G prov-client-crt --from-file=client.crt
kubectl create configmap -n $NS_DRAX_4G prov-client-key --from-file=client.key
kubectl create configmap -n $NS_DRAX_4G prov-ca-crt --from-file=ca.crt
```

!!! warning
    The names of these configmaps are critical - these names are referenced specifically in other parts of Accelleran's software.

#### 4G : Prepare the values configuration file

If you plan to install the 4G components (and you have the license to support this), you need to make a few other adjustments in the ric-values.yaml file 

we first need to enable the 4G components:

``` yaml
global:
    enable4G: true    
```

Find and update the following fields with the names of the Namespaces which you've chosen to use:

``` yaml
4g-radio-controller:
  config:
    # The namespace where the 4G CU pods will be installed
    l3Namespace: "$NS_4G_CU"
```

Finally, if you are using the Provisioner, you need to configure the provisioner-dhcp component.
This component is using the DHCP protocol, and hence needs to know the default interface of the machine where dRAX is installed.
This interface will be used to reach the cells, hence make sure the cells are reachable through the interface specified here.
The configuration is located here:

``` yaml
provisioner-dhcp:
  configuration:
    Interface: eno1
```

Here, change `eno1` to the intended interface on your machine.


#### 4G : Pre-provisioning the list of E1000 DUs

If you already have access to the Accelleran E1000 DUs that you wish to use with this dRAX installation, we can pre-provision the information regarding these during installation.
This can also be done later, or if new E1000 DUs are added.

Each Accelleran E1000 has a Model, a Hardware Version, and a Serial Number - this information is displayed on the label attached to the unit, and is required in order to pre-provision the DUs.
A unique identifier is constructed from this information in the following format: `Model-HardwareVersion-SerialNumber`.
This identifier is then listed, along with a unique name, for each E1000.
This name could be as simple as `du-1` - all that matters is that it is unique in this dRAX installation.

Edit the `drax-4g-values.yaml` file, adding a new line for each E1000 that you would like to pre-provision:

``` yaml
configurator:
    provisioner:
        # Pre-provision the E1000 4G DUs, create a list of identifier: name as shown below
        cells:
            E1011-GC01-ACC000000000001: du-1
            E1011-GC01-ACC000000000002: du-2
```

(In this example, the E1000 specific Model is E1011, the Hardware Version is GC01, and the Serial Numbers were 0001, and 0002. Update this according to the values of your E1000s.)

!!! note
    If your dRAX installation and Accelleran E1000s will not be on the same subnet, after completing the previous step, please also follow [Appendix: dRAX and Accelleran E1000s on different subnets](#appendix-drax-and-accelleran-e1000s-on-different-subnets).


#### 4G : Update E1000 DUs

The Accelleran E1000 DUs need to be updated to match the new version of dRAX.
The following steps will guide you through this update process.
As a prerequisite, the E1000s must be powered on, and you must be able to connect to them via SSH.
If you do not have an SSH key to access the E1000s, contact Accelleran's support team.

#### 4G : Download the E1000 update files

There is a server included with the dRAX installation that hosts the E1000 update files.
Depending on the E1000 type (FDD or TDD), you can grab those files using the following command:

``` bash
curl http://$NODE_IP:30603/fdd --output fdd-update.tar.gz
curl http://$NODE_IP:30603/tdd --output tdd-update.tar.gz
```

!!! note
    Please replace the $NODE_IP with the advertised address of your Kubernetes

#### 4G : Update software of E1000

Copy the TDD or FDD image to the E1000 in /tmp/.
For example:

``` bash
scp -i ~/guest.key tdd-update.tar.gz guest@<ip_of_e1000>:/tmp/update.tar.gz
```

SSH into the E1000:

``` bash
ssh -i guest.key guest@<ip_of_e1000>
```

Now execute:

``` bash
do_update.sh
```

#### 4G : Verify the update of E1000 on the unit and the alignment with dRAX version

To validate that the newly updated software matches with the installed version of dRAX, we can run the following steps:

SSH into the E1000:

``` bash
ssh -i guest.key guest@<ip_of_e1000>
```

Note down the Git commit of the newly installed software:

``` bash
strings /mnt/app/acc.tar | grep Git
```

Now on the dRAX server, we need to retrieve the Git commit of the `4g-radio-controller` to compare.

Find the correct pod name using this command:

``` bash
kubectl get pods | grep 4g-radio-controller
```

With the full pod name, run the following command (replace xxx with the correct identifier from the previous command):

``` bash
kubectl exec -it drax-4g-4g-radio-controller-xxxx -- cat /data/oranC | strings | grep Git
```

The two commits must match, if not please verify the installation and contact Accelleran for support.

### Install the dRAX RIC and Dashboard

Install the RIC and Dashboard with Helm (if installing without dedicated namespaces, leave off the -n option):

``` bash
helm install ric acc-helm/ric --version $RIC_VERSION --values ric-values.yaml -n $NS_DRAX
```
!!! info
    The installation may take up to 5 minutes, it is essential that you wait till the installation is completed and all the pods are in RUNNING or COMPLETE mode, please do **NOT** interrupt the installation by trying to regain control of the command line

To check if the installation was successful first use Helm:

``` bash
helm list
#NAME	NAMESPACE	REVISION	UPDATED                                	STATUS	        CHART    	 APP VERSION
#ric 	default  	1       	2022-08-30 12:23:24.894432912 +0000 UTC	deployed	ric-5.0.0	 5.0.0      
```

Than view the pods that have been created.
``` bash
watch kubectl get pod
```

You should see something like this. You can ignore the status of Jaeger in this release. It is not used at the moment.
> ```
> NAME                                                 READY   STATUS             RESTARTS   AGE
> ric-acc-fiveg-pmcounters-6d47899ccc-k2w66            1/1     Running            0          56m
> ric-acc-kafka-955b96786-lvkns                        2/2     Running            2          56m
> ric-acc-kminion-57648f8c49-g89cj                     1/1     Running            1          56m
> ric-acc-service-monitor-8766845b8-fv9md              1/1     Running            1          56m
> ric-acc-service-orchestrator-869996756d-kfdfp        1/1     Running            1          56m
> ric-cassandra-0                                      1/1     Running            1          56m
> ric-cassandra-1                                      1/1     Running            5          54m
> ric-dash-front-back-end-85db9b456c-r2l6v             1/1     Running            1          56m
> ric-fluent-bit-loki-jpzfc                            1/1     Running            1          56m
> ric-grafana-7488865b58-nwqvx                         1/1     Running            2          56m
> ric-influxdb-0                                       1/1     Running            1          56m
> ric-jaeger-agent-qn6xv                               1/1     Running            1          56m
> ric-kube-eagle-776bf55547-55f5m                      1/1     Running            1          56m
> ric-loki-0                                           1/1     Running            1          56m
> ric-metallb-controller-7dc7845dbc-zlmvv              1/1     Running            1          56m
> ric-metallb-speaker-vsvln                            1/1     Running            1          56m
> ric-metrics-server-b4dd76cbc-hwf6d                   1/1     Running            1          56m
> ric-nats-5g-0                                        3/3     Running            3          55m
> ric-nkafka-5g-76b6558c5f-zs4np                       1/1     Running            1          56m
> ric-prometheus-alertmanager-7d78866cc6-svxc5         2/2     Running            2          56m
> ric-prometheus-kube-state-metrics-585d88b6bb-6kx5l   1/1     Running            1          56m
> ric-prometheus-node-exporter-pxh6w                   1/1     Running            1          56m
> ric-prometheus-pushgateway-55b97997bf-xb2m2          1/1     Running            1          56m
> ric-prometheus-server-846c4bf867-ff4s5               2/2     Running            2          56m
> ric-redis-5g-6f9fbdbcf-j447s                         1/1     Running            1          56m
> ric-vector-84c8b58dbc-cdtmb                          1/1     Running            0          56m
> ric-vectorfiveg-6b8bf8fb4c-79vl7                     1/1     Running            0          56m
> ric-zookeeper-0                                      1/1     Running            1          56m
> ```

### Install dRAX 5G Components

Accelleran's 5G Components are managed and installed via the Dashboard.
From the dRAX Dashboard sidebar, select **New deployment** and then click **5G CU deployment**:

<p align="center">
  <img width="200" height="300" src="../../drax-install/images/dashboard-sidebar-expanded-new-deployment-selected-cu-deployment.png">
</p>


You will reach the **Deploy a new CU component** page.
Here, you have the ability to deploy either a CU-CP or a CU-UP component.
Therefore, you first have to pick one from the drop-down menu:

<p align="center">
  <img width="400" height="300" src="../../drax-install/images/dashboard-deploy-a-new-cu-component.png">
</p>


#### 5G CU-CP Installation

When installing the 5G CU-CP component, there are a number of configuration parameters that should be filled in the **Deploy a new CU component** form once the CU-CP is chosen from the drop-down menu.

The form with the deployment parameters is shown below:
> NOTE : fill in the E1 and F1 address manually according to what's set in the Preperation section in the start of this installation document.
> for F1 it will be the ip address we will also configure the DU with.

![Deploy CU-CP form](../../drax-install/images/dashboard-cu-cp-deployment-2.png)

###### Required Parameters

The deployment parameters are split into required and optional ones.

It is important to pay attention to certain constraints on two of the parameters in order to obtain the desired installation:

- The Instance ID must consist of no more than 16 **lower case** alphanumeric characters or '-', start with an alphabetic character, and end with an alphanumeric character (e.g. 'my-name',  or 'abc-123', but not 123-cucp)
- The maximum number of UE that can be admitted depends also on how many ds-ctrl components get created (by default one per UE) so because occasionally at attach the UE may need two of such components, as a rule of thumb the desired maximum number of UEs must be doubled: if you intend to have at most 2 UEs, set the maximum number of UEs to 4

The required parameters are:

| Required Parameter         | Description                                                                              |
| -------------------------- | ---------------------------------------------------------------------------------------- |
| Instance ID                | The instance ID of the CU-CP component - this must be unique across all CU-CP and CU-UPs |
| Number of supported AMFs   | The maximum number of AMFs which can be connected to at any time                         |
| Number of supported CU-UPs | The maximum number of CU-UPs which can be connected to at any time                       |
| Number of supported DUs    | The maximum number of DUs which can be connected to at any time                          |
| Number of supported RUs    | The maximum number of RUs which can be supported at any time                             |
| Number of supported UEs    | The maximum number of UEs which can be supported at any time                             |

Once the deployment parameters are set, click the submit button to deploy the 5G CU-CP.

###### Optional Parameters

The optional parameters are auto-discovered and auto-filled by dRAX.
As such they do not need to be changed.
However, depending on the use case, you may want to edit them.
In this case, you first have to toggle the **Set optional parameters** to **ON**.
The optional parameters are:

| Optional Parameter      | Description |
| ------------------      | ----------- |
| NATS URL/Port           | Connection details towards NATS. When installing the RIC and Dashboard component, if you set the `enable5g` option to true, a NATS server was deployed, which will be auto-discovered. |
| Redis URL/Port          | Connection details towards Redis. Similar to NATS, if you set the `enable5g` option to true, a Redis server was deployed, which will be auto-discovered. |
| dRAX Node Selector name | If you label your Kubernetes node with the label `draxName`, you can specify the value of that label here and force the CU component to be installed on a specific node in the cluster. |
| Namespace               | The namespace where the CU component should be installed. |
| E1 Service IP           | Part of the CU-CP is the E1 interface. The 5G component will be exposed outside of Kubernetes on a specific IP and the E1 port of 38462. This IP is given by MetalLB, which is part of the 5G infrastructure. If this field is set to auto, MetalLB will give out the first free IP, otherwise you can specify the exact IP to be used. NOTE: The IP must be from the MetalLB IP pool defined in [Enabling 5G components](#enabling-5g-components). |
| F1 Service IP           | Similar to E1, you can specify the IP to be used for the F1 interface. NOTE: Again it has to be from the MetalLB IP pool defined in [Enabling 5G components](#enabling-5g-components). |
| NETCONF Server Port     | The NETCONF server used for configuring the 5G CU-CP component is exposed on the host machine on a random port. You can override this and set a predefined port. NOTE: The exposed port has to be in the Kubernetes NodePort range. |
| Version                 | This is the version of the 5G CU component. By default, the latest stable version compatible with the dRAX version is installed. Other released versions can be specified, but compatibility is not guaranteed. |

#### 5G CU-UP Installation

When deploying the 5G CU-UP component, there is only one required parameter in the **Deploy a new CU component** form.
The form with the deployment parameters is shown below:

![Deploy CU-UP form](../../drax-install/images/dashboard-cu-up-deployment-2.png)

###### Required Parameters

The required deployment parameter is:

| Required Parameter | Description |
| ------------------ | ----------- |
| Instance ID        | The instance ID of the CU-UP component. As before, the Instance ID must be unique, different from the relative CU-CP and must consist of at most 16 lower case alphanumeric characters or '-', start with an alphabetic character, and end with an alphanumeric character (e.g. 'my-name',  or 'abc-123'). 

###### Optional Parameters

Optional parameters are auto-discovered and auto-filled by dRAX.
As such they do not need to be changed.
However, depending on the use case, you may want to edit them.
In this case, you first have to toggle the **Set optional parameters** to **ON**.
The optional parameters are:

| Optional Parameter      | Description |
| ----------------------- | ----------- |
| NATS URL/Port           | The details where the NATS is located. When installing the RIC and Dashboard component, if you set the enable5g option to true, the 5G infrastructure will be deployed, which includes the 5G NATS. This NATS is auto-discovered and auto-filled here |
| Redis URL/Port          | Like NATS, a 5G REDIS is deployed and autofilled |
| dRAX Node Selector name | If you label your Kubernetes node with the label `draxName`, you can specify the value of that label here and force the CU component to be installed on a specific node in the cluster |
| Namespace               | The namespace where the CU component will be installed |
| NETCONF Server Port     | The NETCONF server used for configuring the 5G CU-UP component is exposed on the host machine on a random port. You can override this and set a predefined port. NOTE: The exposed port has to be in the Kubernetes NodePort range. |
| Version                 | This is the version of the 5G CU component. By default, the latest stable version compatible with the dRAX version is installed. Other versions can be specified, but compatibility is not guaranteed |

Now the installation of CU is done. To see the pods and services execute following steps. Here is what to expect.


### Optional : Install xApps 
For a basic installation you can skip this chapter.

Compatible xApps can be managed and installed via the Dashboard.
This can be achieved by clicking on **New deployment** in the sidebar, and then clicking **xApp deployment:**

<p align="center">
  <img width="200" height="300" src="../../drax-install/images/dashboard-sidebar-expanded-new-deployment-selected-xapp-deployment.png">
</p>

In the resulting form, xApps can be deployed either from a remote Helm repository or by uploading a local packaged Helm chart file.

![Deploy an xApp](../../drax-install/images/dashboard-xapp-deployment.png)

In the "Metadata" section of the form, the user inputs information regarding the xApp name, the organization and team who own the xApp, the version of the xApp Helm Chart and the namespace where the xApp will be deployed on.

When deploying an xApp from a remote Helm repository, the user needs to specify the name of the remote repository, its URL and the Helm chart name.
Optionally, the user can upload a values configuration file to override the default configuration present in the remote Helm Chart.

When deploying an xApp using the second method, the user can upload a local packaged Helm chart (a .tgz file produced by the command "helm package &lt;chartName>") which contains the dRAX compatible xApp and optionally an accompanying values configuration file.

<p align="center">
  <img width="400" height="300" src="../../drax-install/images/dashboard-local-helm-upload.png">
</p>


Upon clicking the "Submit" button, the xApp will be deployed on the user-defined namespace in Kubernetes following the naming convention "organization-team-xappname-version".

#### Install XDP
This chapter will improve the CU performance.

go to the CU VM (supposedly ad@10.10.10.201)

``` bash
ssh ad@10.10.10.201
```

login to docker

``` bash
docker login -u DOCKER_USER -p DOCKER_PASS
```

Determine the **Instance ID** of your CUUP by simply consulting the Dashboard and checking the CUUP configuration of your installed CUUP as in the picture below (the field on left, marked as Id here **cuup-1**):

<p align="center">
  <img width="400" height="300" src="../../drax-install/images/dashboard-cu-config-page.png">
</p>

Copy/Paste the below and 2 scripts are generated
  * startXdpAfterBoot.sh
  * deploy_xdpupsappl.sh


Now here below the 2 scripts that get generated by copy/pasting the below in one go:

check of course before proceeding the parameters below:

 -i instanceID
 -g  VM IP
 -G the GTP interface of your deployment
 -t the CU version (helm list will show something like R3.3.0_hoegaarden)

``` bash
#!/bin/bash

until [ `docker ps | wc -l` -ge "15" ]
do
    echo "We are waiting for first 15 docker containers."
    echo "Current amount of docker containers running: "$(docker ps | wc -l)
    sleep 1
done

if kubectl get pods | grep ups ; then
    echo "UPS pods are still running. Deleting..."
    kubectl get pods --no-headers=true | awk '/ups/{print $1}'| xargs  kubectl delete pod
else
    echo "UPS Pods are not present. Doing nothing."
fi

if docker ps | grep xdp ; then
    echo "XDP Already running. Doing nothing."
else
    echo "XDP not found. Starting...:"
     /home/ad/install/q3/deploy_xdpupsappl.sh -i cuup-1 -g 10.10.10.201 -G eno1 -t R3.3.0_hoegaarden
     docker logs xdp_cu_up
fi

```

``` bash
cat > deploy_xdpupsappl.sh <<EOF
#!/bin/bash

mtu=1460

node_ip="\$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(.type == "InternalIP")].address}')"
instance_id=

while getopts 'i:G:g:n:n:t:' option; do
	case "\$option" in
		i)
		  instance_id="\$OPTARG"
		;;
		G)
			gtp_iface="\$OPTARG"
		;;
		g)
			gtp_ip="\$OPTARG"
		;;
		m)
			mtu="\$OPTARG"
		;;
		n)
			node_ip="\$OPTARG"
		;;
		t)
			build_tag="\$OPTARG"
		;;
	esac
done

if [ -z "\$instance_id" ]; then
	echo "Error: no instance ID (-i) specified" >&2
	exit 1
fi
if [ -z "\$gtp_iface" ]; then
	echo "Error: no GTP interface (-G) specified" >&2
	exit 1
fi
if [ -z "\$gtp_ip" ]; then
	echo "Error: no GTP IP (-g) specified" >&2
	exit 1
fi
if [ -z "\$mtu" ]; then
	echo "Error: no MTU (-m) specified" >&2
	exit 1
fi
if [ -z "\$node_ip" ]; then
	echo "Error: no node IP (-n) specified" >&2
	exit 1
fi
if [ -z "\$build_tag" ]; then
	echo "Error: no build tag (-t) specified" >&2
	exit 1
fi


config_dir="\$(mktemp -d)"

cat >"\$config_dir/bootstrap" <<NESTED_EOF
redis.hostname:\$node_ip
redis.port:32200
instance.filter:\$instance_id
NESTED_EOF

cat >"\$config_dir/zlog.conf" <<NESTED_EOF
[global]
strict init = true
buffer min = 64K
buffer max = 64K
rotate lock file = /tmp/zlog.lock

[formats]
printf_format = "%d(%b %d %H:%M:%S).%ms %8.8H %m%n"
[rules]
user.* >stdout ;printf_format
NESTED_EOF

docker run \
	--name xdp_cu_up \
	--detach \
	--rm \
	--privileged \
	--user 0 \
	--network host \
	--volume "\$config_dir:/home/accelleran/5G/config:ro" \
	--env "IFNAME=\$gtp_iface" \
	--env "NATS_SERVICE_URL=nats://\$node_ip:31100" \
	--env "MTU_SIZE=\$mtu" \
	--env __APPNAME=cuUp \
	--env __APPID=1 \
	--env ZLOG_CONF_PATH=/home/accelleran/5G/config/zlog.conf \
	--env BOOTSTRAP_FILENAME=/home/accelleran/5G/config/bootstrap \
	--env XDP_OBJECT_FILE=/home/accelleran/5G/xdp_gtp_kernel.o \
	--env LD_LIBRARY_PATH=/home/accelleran/5G/lib \
	--env HOSTMODE=true \
	"accelleran/xdpupsappl:\$build_tag" \
	/home/accelleran/5G/xdpUpsAppl.exe \
	--uplink "\$gtp_ip" \
	--downlink "\$gtp_ip" \
	--bind "\$gtp_ip" \

EOF

chmod 777 *

```

Startup the xdp in the directory where your script is:
``` bash
./startXdpAfterBoot.sh >> /tmp/xdp_bootscript_response
```

Make the run of the script boot persistent by putting it in crontab
``` bash
crontab -e
```

Add this line into the crontab editor file. Change the ```$USER``` and install ```install_directory``` accordingly.
Check the preperation page.

``` bash
@reboot /<fullpath-to-script>/startXdpAfterBoot.sh >> /tmp/xdp_bootscript_response
```

execute to verify
``` bash
crontab -l
```

## Verifying the dRAX installation

### Monitoring via the Kubernetes API

As specified in the previous sections of this document, the installation of Accelleran dRAX consists of multiple components.
Exactly which are installed depends on the choices made during the installation process.
All Pods that have been installed should be running correctly at this point though.
To verify this, we can use the following command:

``` bash
watch "kubectl get pods -A | grep -e ric- -e drax-4g- -e acc-5g- -e l3-"
```
This is what to expect

```
NAME                                                     READY   STATUS             RESTARTS   AGE
acc-5g-cu-cp-cucp-01-amf-controller-5cb5d654fd-p75n9     1/1     Running            0          7m15s
acc-5g-cu-cp-cucp-01-cu-up-controller-75859656cd-t9shf   1/1     Running            0          7m14s
acc-5g-cu-cp-cucp-01-ds-ctrl-0                           1/1     Running            0          7m15s
acc-5g-cu-cp-cucp-01-ds-ctrl-1                           1/1     Running            0          6m39s
acc-5g-cu-cp-cucp-01-ds-ctrl-10                          1/1     Running            0          6m18s
acc-5g-cu-cp-cucp-01-ds-ctrl-11                          1/1     Running            0          6m16s
acc-5g-cu-cp-cucp-01-ds-ctrl-12                          1/1     Running            0          6m15s
acc-5g-cu-cp-cucp-01-ds-ctrl-13                          1/1     Running            0          6m14s
acc-5g-cu-cp-cucp-01-ds-ctrl-14                          1/1     Running            0          6m13s
acc-5g-cu-cp-cucp-01-ds-ctrl-15                          1/1     Running            0          6m11s
acc-5g-cu-cp-cucp-01-ds-ctrl-2                           1/1     Running            0          6m36s
acc-5g-cu-cp-cucp-01-ds-ctrl-3                           1/1     Running            0          6m34s
acc-5g-cu-cp-cucp-01-ds-ctrl-4                           1/1     Running            0          6m31s
acc-5g-cu-cp-cucp-01-ds-ctrl-5                           1/1     Running            0          6m29s
acc-5g-cu-cp-cucp-01-ds-ctrl-6                           1/1     Running            0          6m27s
acc-5g-cu-cp-cucp-01-ds-ctrl-7                           1/1     Running            0          6m25s
acc-5g-cu-cp-cucp-01-ds-ctrl-8                           1/1     Running            0          6m23s
acc-5g-cu-cp-cucp-01-ds-ctrl-9                           1/1     Running            0          6m20s
acc-5g-cu-cp-cucp-01-du-controller-8477b5f5c8-69j26      1/1     Running            0          7m15s
acc-5g-cu-cp-cucp-01-e1-cp-0                             1/1     Running            0          7m15s
acc-5g-cu-cp-cucp-01-f1-ap-0                             1/1     Running            0          7m15s
acc-5g-cu-cp-cucp-01-f1-ap-1                             1/1     Running            0          6m48s
acc-5g-cu-cp-cucp-01-f1-ap-2                             1/1     Running            0          6m43s
acc-5g-cu-cp-cucp-01-gnb-controller-7d666fdfdd-lps9c     1/1     Running            0          7m14s
acc-5g-cu-cp-cucp-01-netconf-8974d4495-f5mln             1/1     Running            0          7m15s
acc-5g-cu-cp-cucp-01-ng-ap-0                             1/1     Running            0          7m15s
acc-5g-cu-cp-cucp-01-pm-controller-7869f89778-hf228      1/1     Running            0          7m15s
acc-5g-cu-cp-cucp-01-res-mgr-cd6c87484-2v8s4             1/1     Running            0          7m15s
acc-5g-cu-cp-cucp-01-rr-ctrl-0                           1/1     Running            0          7m15s
acc-5g-cu-cp-cucp-01-rr-ctrl-1                           1/1     Running            0          6m43s
acc-5g-cu-cp-cucp-01-rr-ctrl-2                           1/1     Running            0          6m41s
acc-5g-cu-cp-cucp-01-sctp-f46df5cfb-4kzxh                1/1     Running            0          7m15s
acc-5g-cu-up-cuup-01-cu-up-0                             1/1     Running            0          6m54s
acc-5g-cu-up-cuup-01-cu-up-1                             1/1     Running            0          6m54s
acc-5g-cu-up-cuup-01-e1-sctp-up-868897844f-xh4rx         1/1     Running            0          6m54s
acc-5g-cu-up-cuup-01-netconf-6746749b49-kdqbq            1/1     Running            0          6m54s
acc-5g-cu-up-cuup-01-pm-controller-up-57f874bbdb-ttg5k   1/1     Running            0          6m54s
acc-5g-cu-up-cuup-01-res-mgr-up-589689966c-9txd8         1/1     Running            0          6m54s
busybox                                                  1/1     Running            2          160m
ric-acc-fiveg-pmcounters-6d47899ccc-k2w66                1/1     Running            0          71m
ric-acc-kafka-955b96786-lvkns                            2/2     Running            2          71m
ric-acc-kminion-57648f8c49-g89cj                         1/1     Running            1          71m
ric-acc-service-monitor-8766845b8-fv9md                  1/1     Running            1          71m
ric-acc-service-orchestrator-869996756d-kfdfp            1/1     Running            1          71m
ric-cassandra-0                                          1/1     Running            1          71m
ric-cassandra-1                                          1/1     Running            5          69m
ric-dash-front-back-end-85db9b456c-r2l6v                 1/1     Running            1          71m
ric-fluent-bit-loki-jpzfc                                1/1     Running            1          71m
ric-grafana-7488865b58-nwqvx                             1/1     Running            2          71m
ric-influxdb-0                                           1/1     Running            1          71m
ric-jaeger-agent-qn6xv                                   1/1     Running            1          71m
ric-kube-eagle-776bf55547-55f5m                          1/1     Running            1          71m
ric-loki-0                                               1/1     Running            1          71m
ric-metallb-controller-7dc7845dbc-zlmvv                  1/1     Running            1          71m
ric-metallb-speaker-vsvln                                1/1     Running            1          71m
ric-metrics-server-b4dd76cbc-hwf6d                       1/1     Running            1          71m
ric-nats-5g-0                                            3/3     Running            3          70m
ric-nkafka-5g-76b6558c5f-zs4np                           1/1     Running            1          71m
ric-prometheus-alertmanager-7d78866cc6-svxc5             2/2     Running            2          71m
ric-prometheus-kube-state-metrics-585d88b6bb-6kx5l       1/1     Running            1          71m
ric-prometheus-node-exporter-pxh6w                       1/1     Running            1          71m
ric-prometheus-pushgateway-55b97997bf-xb2m2              1/1     Running            1          71m
ric-prometheus-server-846c4bf867-ff4s5                   2/2     Running            2          71m
ric-redis-5g-6f9fbdbcf-j447s                             1/1     Running            1          71m
ric-vector-84c8b58dbc-cdtmb                              1/1     Running            0          71m
ric-vectorfiveg-6b8bf8fb4c-79vl7                         1/1     Running            0          71m
ric-zookeeper-0                                          1/1     Running            1          71m
```
Another check you need to do is this one. 
``` 
kubectl get services
```
you can see 4 External IP addresses. Those ip addresses are the ones of the range we filled in in the ric-values.yaml file. The 2 last in the range are of the E1 and F1 service. The first two are selected the handle the GTP traffic.
```
NAME                                TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                     AGE   
acc-5g-cu-cp-cucp-01-sctp-e1        LoadBalancer   10.104.225.53    10.55.7.130   38462:32063/SCTP                                                                            6m10s 
acc-5g-cu-cp-cucp-01-sctp-f1        LoadBalancer   10.103.34.228    10.55.7.131   38472:31066/SCTP                                                                            6m10s 
acc-5g-cu-up-cuup-01-cu-up-gtp-0    LoadBalancer   10.96.213.103    10.55.7.120   2152:32081/UDP                                                                              5m49s 
acc-5g-cu-up-cuup-01-cu-up-gtp-1    LoadBalancer   10.99.208.214    10.55.7.121   2152:30575/UDP                                                                              5m49s 
acc-service-monitor                 NodePort       10.104.125.9     <none>        80:30500/TCP                                                                                70m   
acc-service-orchestrator            NodePort       10.111.157.49    <none>        80:30502/TCP                                                                                70m   
kubernetes                          ClusterIP      10.96.0.1        <none>        443/TCP                                                                                     160m  
netconf-cucp-01                     NodePort       10.110.18.130    <none>        830:32285/TCP                                                                               6m10s 
netconf-cuup-01                     NodePort       10.103.120.206   <none>        830:31705/TCP                                                                               5m49s 
ric-acc-fiveg-pmcounters            NodePort       10.98.3.182      <none>        8000:30515/TCP                                                                              70m   
ric-acc-kafka                       NodePort       10.98.24.152     <none>        9092:31090/TCP,9010:32537/TCP,5556:32155/TCP                                                70m   
ric-acc-kminion                     ClusterIP      10.107.221.30    <none>        8080/TCP                                                                                    70m   
ric-cassandra                       ClusterIP      None             <none>        7000/TCP,7001/TCP,7199/TCP,9042/TCP,9160/TCP                                                70m   
ric-dash-front-back-end             NodePort       10.106.72.78     <none>        5000:31315/TCP                                                                              70m   
ric-dash-front-back-end-websocket   NodePort       10.102.245.64    <none>        5001:31316/TCP                                                                              70m   
ric-grafana                         NodePort       10.96.41.39      <none>        80:30300/TCP                                                                                70m   
ric-influxdb                        ClusterIP      10.108.225.110   <none>        8088/TCP                                                                                    70m   
ric-influxdb-api                    NodePort       10.105.161.178   <none>        8086:30303/TCP                                                                              70m   
ric-jaeger-agent                    ClusterIP      10.103.0.234     <none>        5775/UDP,6831/UDP,6832/UDP,5778/TCP,14271/TCP                                               70m   
ric-jaeger-collector                ClusterIP      10.100.187.234   <none>        14250/TCP,14268/TCP,14269/TCP                                                               70m   
ric-jaeger-query                    NodePort       10.97.254.197    <none>        80:31445/TCP,16687:31025/TCP                                                                70m   
ric-kube-eagle                      ClusterIP      10.102.90.103    <none>        8080/TCP                                                                                    70m   
ric-loki                            NodePort       10.108.39.131    <none>        3100:30302/TCP                                                                              70m   
ric-loki-headless                   ClusterIP      None             <none>        3100/TCP                                                                                    70m   
ric-metrics-server                  ClusterIP      10.105.180.254   <none>        443/TCP                                                                                     70m   
ric-nats-5g                         NodePort       10.107.246.192   <none>        4222:31100/TCP,6222:32053/TCP,8222:30606/TCP,7777:30168/TCP,7422:30680/TCP,7522:31616/TCP   70m   
ric-prometheus-alertmanager         ClusterIP      10.106.127.91    <none>        80/TCP                                                                                      70m   
ric-prometheus-kube-state-metrics   ClusterIP      None             <none>        80/TCP,81/TCP                                                                               70m   
ric-prometheus-node-exporter        ClusterIP      None             <none>        9100/TCP                                                                                    70m   
ric-prometheus-pushgateway          ClusterIP      10.105.167.58    <none>        9091/TCP                                                                                    70m   
ric-prometheus-server               NodePort       10.97.205.182    <none>        80:30304/TCP                                                                                70m   
ric-redis-5g                        NodePort       10.96.155.105    <none>        6379:32200/TCP                                                                              70m   
ric-zookeeper                       NodePort       10.109.78.254    <none>        2181:30305/TCP                                                                              70m   
ric-zookeeper-headless              ClusterIP      None             <none>        2181/TCP,3888/TCP,2888/TCP                                                                  70m   
```

The listed Pods should either all be Running and fully Ready (i.e. all expected instances are running - 1/1, 2/2, etc.), or Completed - it may take a few minutes to reach this state.
The number of restarts for each pod should also stabilize and stop increasing.

If something crashes or you need to restart a pod, you can use the scale command (no need to add the instance of the pod) - for example:

``` bash
kubectl scale deployment ric-prometheus-alertmanager --replicas=0
kubectl scale deployment ric-prometheus-alertmanager --replicas=1
```

### SCTP connections setup
Check services and verify E1 and F1 ip address.

``` bash
kubectl get services
```

Verify SCTP connection is setup. Expecting  HB REQ and HB ACK tracing with this tcpdump commandline.
``` bash
sudo tcpdump -i any or 38462
```


## Appendix: dRAX Provisioner - Keys and Certificates Generation

In general, TLS certificates only allow you to connect to a server if the URL of the server matches one of the subjects in the certificate configuration.

This section assumes the usage of `openssl` to handle TLS security due to its flexibility, even if  it is both complex to use and easy to make mistakes.
Customers can choose to use different options to generate the keys and certificates as long as of course the final output matches the content of this section.

### Create the certificates

#### Create the server.key

First thing is to create a key (if it doesn't exist yet):

``` bash
openssl genrsa -out server.key 4096
```

This command will create a RSA based server key with a key length of 4096 bits.

#### Create a server certificate

First, create the `cert.conf`.
Create a file like the example below and save it as `cert.conf`:

```
[ req ]
default_bits        = 2048
default_keyfile     = server-key.pem
distinguished_name  = subject
req_extensions      = req_ext
x509_extensions     = req_ext
string_mask         = utf8only

[ subject ]
countryName         = Country Name (2 letter code)
countryName_default     = BE

stateOrProvinceName     = State or Province Name (full name)
stateOrProvinceName_default = Example state

localityName            = Locality Name (eg, city)
localityName_default        = Example city

organizationName         = Organization Name (eg, company)
organizationName_default    = Example company

commonName          = Common Name (e.g. server FQDN or YOUR name)
commonName_default      = Example Company

emailAddress            = Email Address
emailAddress_default        = test@example.com

[ req_ext ]

subjectKeyIdentifier        = hash
basicConstraints        = CA:FALSE
keyUsage            = digitalSignature, keyEncipherment
subjectAltName          = @alternate_names
nsComment           = "OpenSSL Generated Certificate"

[ alternate_names ]
DNS.1        = localhost
IP.1         = 10.0.0.1
IP.2         = 10.20.20.20
```

Fill in the details, like the country, company name, etc.

**IMPORTANT:** Edit the last line of the file.
`IP.2` should be equal to IP where the provisioner will be running.
This is the `$NODE_IP` from the planning phase.
The default is set to 10.20.20.20.

To create the server certificate, use the following command:

``` bash
openssl req -new -key server.key -config cert.conf -out server.csr -batch
```

Command explanation:

  - `openssl req -new`: create a new certificate
  - `-key server.key`: use server.key as the private half of the certificate
  - `-config cert.conf`: use the configuration as a template
  - `-out server.csr`: generate a csr
  - `-batch`: don't ask about the configuration on the terminal

#### Create a self-signed client certificate

To create the client certificate, use the following command:

``` bash
openssl req -newkey rsa:4096 -nodes -keyout client.key -sha384 -x509 -days 3650 -out client.crt -subj /C=XX/ST=YY/O=RootCA
```

This command will create a `client.key` and `client.crt` from scratch to use for TLS-based authentication, in details the options are:

  - `openssl req`: create a certificate
  - `-newkey rsa:4096`: create a new client key
  - `-nodes`: do not encrypt the newly create client key with a passphrase (other options are -aes)
  - `-keyout client.key`: write the key to client.key
  - `-x509`: sign this certificate immediately
  - `-sha384`: use sha384 for signing the certificate`
  - `-days 3650`: this certificate is valid for ten years
  - `-subj /C=XX/ST=YY/O=RootCA`: use some default configuration
  - `-out client.crt`: write the certificate to client.crt

#### Sign the server certificate using the root certificate authority key

The server certificate needs to be signed by Accelleran.
To do so, please contact the Accelleran Customers Support Team and send us the following files you created previously:

* server.csr
* cert.conf

You will receive from Accelleran the following files:

* signed server.crt
* ca.crt

#### Verify the certificates work

The following commands should be used and return both OK:

``` bash
openssl verify -CAfile client.crt client.crt
openssl verify -CAfile ca.crt server.crt
```


## Appendix: License Error Codes

Sometimes you might run into issues when trying to launch dRAX due to a licensing error. A list of possible error codes is provided below:

|ID        | Tag                   | Explanation                                                                       |
|----------|-----------------------| ----------------------------------------------------------------------------------|
| E001      | ENotInEnv             | Environment variable not set                                                      |
| E002      | EInvalidUTF8          | The content of the environment varable is not valid UTF8                          |
| E003      | ECannotOpen          |  Cannot open license file, was it added as a secret with the right name? To verify whether it's loaded correctly, run: ```  bash kubectl get secret accelleran-license -o'jsonpath={.data.license\\.crt}' ```   which should give you a base64 encoded dump. |
|E004|ELicenseExpired|Your license is expired! You'll likely need a new license from Accelleran|
|E005|EDecryption|An error occurred during decryption
|E006|EVerification|An error occurred during verification
|E007|EMissingPermission|You do not have the permissions to execute the software. You'll likely need a more permissive license from Accelleran.
|E008|ESOError|Inner function returned an error
|E009|ERunFn|Cannot find the correct function in the library
|E010|ELoadLibrary|Cannot load the .so file
|E011|ETryWait|An error occurred while waiting for the subprocess to return
|E012|ESpawn|Could not spawn subprocess
|E013|EWriteDecrypted|Cannot write to file descriptor
|E014|EMemFd|Cannot open memory file descriptor
|E015|ECypher|Cannot create cypher|

## Appendix : Remove existing deployments

In order to continue with the remaining steps, we remove the existing deployments of our charts.
Note that this will not remove the data, so any configured components should remain once the installation is completed.

It may be that the previous versions used different names for the Helm deployments, so to check the correct names we can use the `helm list` command:

``` bash
helm list
#NAME        	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART             	APP VERSION               
#acc-5g-cu-cp	default  	1       	2022-01-21 15:16:35.893230618 +0000 UTC	deployed	acc-5g-cu-cp-3.0.0	release-2.3-duvel-8b8d7f05
#acc-5g-cu-up	default  	1       	2022-01-21 15:16:44.931753616 +0000 UTC	deployed	acc-5g-cu-up-3.0.0	release-2.3-duvel-8b8d7f05
#acc-helm-ric	default  	1       	2022-01-09 17:20:52.860528687 +0000 UTC	deployed  	ric-4.0.0         	4.0.0                     

```

In the above example, the installations are called `acc-5g-cu-cp` , acc-5g-cu-up and `ric`, so the required commands would be:

``` bash
helm uninstall acc-5g-cu-cp
helm uninstall acc-5g-cu-up
helm uninstall ric
```

Please wait until all the pods and resources of the previous dRAX installation are deleted.
You can view them by:

``` bash
watch kubectl get pods -A
```

You can now continue with the remaining steps.
