# DRAX Deployment

This will can be done after preparing the cluster as shown [here](/drax-docs/K8s/1.24)

## 1. Preparation

- Create Secrets with License of RIC and with Dockerhub credentials to access Accelleran repositories.
```bash
kubectl create secret docker-registry accelleran-secret --docker-server=docker.io --docker-username=<username> --docker-password=<password> --docker-email=<email>
kubectl create secret generic accelleran-license --from-file=license.crt
```

- Add the helm repository to be used for drax.
```bash
helm repo add accelleran https://accelleran.github.io/helm-charts
helm repo update
```

- Create `drax-values.yaml` values file:
```bash
tee drax-values.yaml <<EOF
global:
  kubeIp: "10.55.5.3"

  accelleranLicense:
    enabled: "true"
    licenseSecretName: "accelleran-license"

e2-t:
  #global:
  #  tag: "6.0.3"
  numOfE2Nodes: 3
  e2-t-sctp:
    service:
      type:  LoadBalancer
      loadBalancerIP: 10.55.5.39

loki-deleter:
  enabled: true

EOF
```


## 2. Deployment

- Deploy DRAX
```bash
helm install drax accelleran/drax --version 11.0.0 --values drax-values.yaml --debug
```
- Make sure all pods are operating normaly.
```bash
watch kubectl get pods
```

## 3. Uninstalling DRAX

- Undeploy using helm
```bash
helm uninstall drax
kubectl delete pvc drax-du-influxdb drax-influxdb2
kubectl delete secret drax-du-influxdb-auth drax-influxdb2-auth
```
