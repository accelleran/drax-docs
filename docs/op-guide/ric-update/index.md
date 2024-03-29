# RIC
This section is about upgrading your existing RIC to a new Release, as a rule Accelleran will regularly issue quarterly Releases with new features, 
bug fixes, etc and we will therefore recommend regularly to move forward to a new Release. The aim of this section is to take the minimal amount of steps to get the system back to operational: if you do not have an already operational System please contact Accelleran as the full installation from ground zero is beyond the scope of this section.

## Remove an existing deployment

Login first on the machine where your RIC is deployed (typically a VM) and locate the installation directory where your helm charts are (often a directory in your home with a name that reminds of the release you are on ex. Q3Rel or q3release)

Note that a SW upgrade will not remove the existing data, so any configured components should remain once the update is completed. Particularly, of course, 
if you wish to keep the previous configuration take note of the CU instance IDs, the E1 and F1 external IP addresses, and make sure they are the same once you recreate them. It is simple to infer these values by checking the Dashboard on the section **gNB Configuration** and clicking on the **show** button. The fields ate highlighted in the following picture:

<p align="center">
  <img width="800" height="300" src="cucp-services.png">
</p>


It may be that the previous versions used different names for the Helm deployments, so to check the correct names we can use the `helm list` command:

``` bash
helm list
#NAME        	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART             	APP VERSION               
#acc-5g-cu-cp	default  	1       	2022-01-21 15:16:35.893230618 +0000 UTC	deployed	acc-5g-cu-cp-3.0.0	release-2.3-duvel-8b8d7f05
#acc-5g-cu-up	default  	1       	2022-01-21 15:16:44.931753616 +0000 UTC	deployed	acc-5g-cu-up-3.0.0	release-2.3-duvel-8b8d7f05
#acc-helm-ric	default  	1       	2022-01-09 17:20:52.860528687 +0000 UTC	deployed  	ric-4.0.0         	4.0.0                     

```

In the above example, the installations are called after the #NAME field, that is `acc-5g-cu-cp` , `acc-5g-cu-up` and `ric`, so the required commands would be:

``` bash
helm uninstall acc-5g-cu-cp
helm uninstall acc-5g-cu-up
helm uninstall ric
```

Please wait until all the pods and resources of the previous dRAX installation are deleted. As a side note one could also uninstall the CUCP and CUUP using the uninstall button on the dashboard
You can view them by:

``` bash
watch kubectl get pods -A
```

As a side note one could also uninstall the CUCP and CUUP using the uninstall button on the dashboard:

<p align="center">
  <img width="700" height="350" src="../../drax-install/images/dashboard-cu-config-page.png">
</p>


You can now continue with the re-installation

## Install the new version

You can proceed with the update of the new version once you verify the folowing simple prerequisites:

1. you have a Kubernetes accelleran secret and a license secret, the commmand `kubectl get secrets` shall return among them these two secrets:

``` bash
accelleran-license                                      Opaque                                1      237d
accelleran-secret                                       kubernetes.io/dockerconfigjson        1      237d
```

2. your ric-values.yaml file does not need an update, that is you don't plan to do any modifications on your RIC deployment and Accelleran did not notify you any new major Release Number, nor any breaking changes
3. you don't have any RIC related pod, any service and any job left alive after the uninstall step:
``` bash
ric@ric-dell5:~$ kubectl get pods
No resources found in default namespace.

ric@ric-dell5:~$ kubectl get services
NAME                                        TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                     
kubernetes                                  ClusterIP      10.96.0.1        <none>        443/TCP                                                                                     

ric@ric-dell5:~$ kubectl get jobs
No resources found in default namespace.
```

#### Update Helm Charts

To update to our latest version, we need to update the Helm charts:

``` bash
helm repo update
```

Install the RIC and Dashboard with Helm (if installing without dedicated namespaces, leave off the -n option):

``` bash
helm install ric acc-helm/ric --version $RIC_VERSION --values ric-values.yaml -n $NS_DRAX
```

!!! info The installation may take up to 5 minutes, it is essential that you wait till the installation is completed and all the pods are in RUNNING or COMPLETE mode, please do **NOT** interrupt the installation by trying to regain control of the command line

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
>```
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
  <img width="300" height="200" src="../../drax-install/images/dashboard-deploy-a-new-cu-component.png">
</p>


#### 5G CU-CP Installation

When installing the 5G CU-CP component, there are a number of configuration parameters that should be filled in the **Deploy a new CU component** form once the CU-CP is chosen from the drop-down menu.

The form with the deployment parameters is shown below:
> NOTE : if you intend to recover the previous CUCP configuration without painfully go through manual review and editing of the other configurations (du, cell wrapper, CUUP) remember to specify exactly the same instance ID previously used and fill in the optional values with the same previous E1 and F1 addresses manually
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

#### Optional Parameters

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


#### Required Parameters

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

Now the installation of CU is done. Verify that all pods are up and running before taking any further step:

``` bash
watch kubectl get pod
```
The output may differ from case to case but it is important to stay till all the pods are either **RUNNING** or **COMPLETE**

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
.
.
.
.
```
!!! warning
    One last important step is to perform a reboot of the VM, in order to ensure that at the next start the XDP is deployed, you don't have to worry about this any further than checking if your crontab has indeed an entry to restart XDP at reboot:

``` bash
crontab -l
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command
@reboot /home/ric/startXdpAfterBoot>>/tmp/xdp_bootscript_response

```

The last line will answer the question
