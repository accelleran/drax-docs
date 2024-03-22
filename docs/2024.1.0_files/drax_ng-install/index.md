# **3. DRAX Deployment**

> After preparing the cluster [Steps](/drax-docs/kubernetes_ng-install)

- Create Secrets with License of RIC and with Dockerhup credentials to access Accelleran repositories. (Consult Accelleran for this Step)
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

# Only disable if the base DU L1 config needs to be overwritten (lab testing cases or engineering builds)
cell-wrapper:
  enabled: true
EOF
```
- Deploy DRAX
```bash
helm install drax accelleran/drax --version 7.0.0 --values drax-values.yaml --debug
```
- Make sure all pods are operating normaly.
```bash
watch kubectl get pods
```

> # Next Step [CU Deployment](/drax-docs/cu_ng-install/)