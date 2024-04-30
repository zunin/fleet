## Generating a sealed secret


### From file
```bash
kubectl create secret generic <kubernetes-secret-name> --dry-run=client --from-file=<filename-on-host>.txt=<path-on-machine>.txt  -o yaml | kubeseal --format=yaml  > <sealed-secret-filename>.yaml
```

### From literal

```bash
kubectl create secret generic github-token --dry-run=client --output=yaml --from-literal=key=secretvalue | kubeseal --format=yaml > <sealed-secret-filename>.yaml
```