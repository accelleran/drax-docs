# DRAX Deployment

This will can be done after preparing the cluster as shown [here](/drax-docs/K8s/1.24)

> PS: All the following steps and sections won't be needed in case of using ansible. Guide available in [5G Integration Repo](https://github.com/accelleran/5g-integration/tree/main/utilities/install_tools/ansible)

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

- Create a values file
```bash
tee drax-values.yaml <<EOF
global:
  kubeIp: "10.55.5.3"

  accelleranLicense:
    enabled: "true"
    licenseSecretName: "accelleran-license"

e2-t:
  numOfE2Nodes: 2
  e2-t-sctp:
    service:
      type:  LoadBalancer
      loadBalancerIP: 10.55.5.39

#cell-wrapper:
#  global:
#    tag: "4.0.0"

EOF
```
- Deploy DRAX
```bash
helm install drax accelleran/drax --version 8.0.0 --values drax-values.yaml --debug
```
- Make sure all pods are operating normaly.
```bash
watch kubectl get pods
```
