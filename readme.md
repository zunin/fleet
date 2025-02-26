## Generating a sealed secret


### From file
```bash
kubectl create secret generic <kubernetes-secret-name> --dry-run=client --from-file=<filename-on-host>.txt=<path-on-machine>.txt  -o yaml | kubeseal --format=yaml  > <sealed-secret-filename>.yaml
```

### From literal

```bash
kubectl create --namespace <<namespace>> secret generic <<k8s-secret-name>> --dry-run=client --output=yaml --from-literal=<<key>>=<<value>> | kubeseal --namespace <<namespace>> --scope namespace-wide --format=yaml > <<filename>>.sealedsecret.yaml
```

## Validate 
```bash
cat <<filename>>.sealedsecret.yaml | kubeseal --validate
```
