# **4. CU Deployment**

> After installing drax [Steps](/drax-docs/drax_ng-install)

## 1. CU CP Deployment

- Create a values file
```bash
tee cu-cp-values.yaml <<EOF
global:

  # The release to install.
  tag: "R4.3.12_leffe"

bootstrap:
  # A unique value that identifies the CU-CP
  instanceId: "cucp-1"

  # The addresses on which NATS and REDIS are listening. These do not need to be changed.
  nats:
    hostname: drax-nats
  redis:
    hostname: drax-redis-master

# The maximum number of components to support.
numOfAmfs: 3
numOfCuUps: 2
numOfDus: 3
numOfCells: 3
numOfUes: 8

nats:
  enabled: false
redis:
  enabled: false


# Below can be used if the IPs need to be fixed
#sctp-f1:
#  service:
#    loadBalancerIP: "10.55.5.30"
#
#sctp-e1:
#  service:
#    loadBalancerIP: "10.55.5.31"
EOF
```


- Deploy CU CP
```bash
helm install cu-cp accelleran/cu-cp --version 7.0.0 --values cu-cp-values.yaml --debug
```
- Make sure all pods are operating normaly.
```bash
watch kubectl get pods
```

## 2. CU UP Deployment

- Find the kubernetes node name
```bash
$ kubectl get nodes
NAME            STATUS   ROLES           AGE    VERSION
testmachine-ric-cu   Ready    control-plane   7d4h   v1.29.1
```

> To use XDP, make sure there is an interface with an IP to be used for the CU UP. (In our example `10.55.5.3`)

- Create a values file as below (make sure to update the nodeName and the XDP uplink and downlink IPs)
```bash
tee cu-up-values.yaml <<EOF
global:

  # The release to install.
  tag: "R4.3.12_leffe"

bootstrap:
  # A unique value that identifies the CU-CP
  instanceId: "cuup-1"

  # The addresses on which NATS and REDIS are listening. These do not need to be changed.
  nats:
    hostname: drax-nats
  redis:
    hostname: drax-redis-master

numberOfUpStacks: 0
xdpUpStacks:
-
  nodeName: testmachine-ric-cu
  ng-u:
    address: "10.55.5.3"
  f1-u:
    address: "10.55.5.3"

nats:
  enabled: false
redis:
  enabled: false
EOF
```


- Deploy CU UP.
```bash
helm install cu-up accelleran/cu-up --version 7.0.0 --values cu-up-values.yaml --debug
```
- Make sure all pods are operating normaly.
```bash
watch kubectl get pods
```

> # Next Step [Cell Wrapper Deployment](/drax-docs/cw_ng-install/)