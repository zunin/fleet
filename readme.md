## Generating a sealed secret

To rotate values in a registered SealedSecret, run `make help` to list targets
and `make help-spotify-client` (for example) to see the required keys.

```sh
make reseal-spotify-client
```

The script shows the target context and Secret before prompting for each value
without echoing it. Press Enter to keep a value, or Ctrl+C to cancel the whole
rotation. If you skip every key, the manifest is left unchanged. It uses the current `kubectl` context unless you pass
`KUBE_CONTEXT=my-cluster`. For multiline values or non-interactive use, pass
`INPUT_DIR=/path/to/values` with one file per key outside the repository.

The Makefile's reseal targets require GNU Make, Bash, [Mike Farah's `yq` v4](https://github.com/mikefarah/yq), standard shell utilities (`base64`, `tr`, `sort`, `dirname`, `mktemp`, `cp`, `mv`, `rm`), `kubectl`, `kubeseal`, and access to the Sealed Secrets controller in the selected context. Python is not required. The command validates the result
before replacing the manifest. It does not apply anything to the cluster;
review the diff before committing it for Flux.

Replace the quoted placeholders. Keep the namespace explicit.

### From a file

```sh
kubectl create secret generic "<secret-name>" --namespace "<namespace>" \
  --dry-run=client --output=yaml --from-file="<key>=<path>" \
  | kubeseal --namespace "<namespace>" --scope namespace-wide --format=yaml \
  > secret.sealedsecret.yaml
```

### From a literal

```sh
kubectl create secret generic "<secret-name>" --namespace "<namespace>" \
  --dry-run=client --output=yaml --from-literal="<key>=<value>" \
  | kubeseal --namespace "<namespace>" --scope namespace-wide --format=yaml \
  > secret.sealedsecret.yaml
```

### Validate

```sh
kubeseal --validate < secret.sealedsecret.yaml
```
