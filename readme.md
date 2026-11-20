## Generating a sealed secret

To rotate values in a SealedSecret, run `make help` to list the targets.

```sh
make reseal-spotify-client
```

Each target passes named options to `scripts/reseal.sh`. The script prompts for
each value without echoing it. Press Enter to keep a value, or Ctrl+C to cancel
before writing. If you skip every key, the manifest is left unchanged. The
commands use the current kubeconfig context. Prompts accept single-line values
and require a terminal.

The reseal targets require GNU Make, Bash, [Mike Farah's `yq` v4](https://github.com/mikefarah/yq), `kubeseal`, and access to the Sealed Secrets controller in the current context. They validate the result before writing the manifest, but the final write is not atomic. They do not apply anything to the cluster; review the diff before committing it for Flux.

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
