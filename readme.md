## Generating a sealed secret

```bash
kubectl create secret generic <kubernetes-secret-name> --dry-run=client --from-file=<filename-on-host>.txt=<path-on-machine>.txt  -o yaml | kubeseal --format=yaml  > <sealed-secret-filename>.yaml
```
