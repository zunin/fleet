kubectl create job encode-replaygain --image nixery.dev/shell/rsgain:master --namespace music --dry-run=client -o yaml \
    | kubectl patch --dry-run=client -o yaml --type json --patch '[{ "op": "replace", "path": "/spec/template/spec/volumes", "value": [{"name": "music-volume", "persistentVolumeClaim": {claimName: "music-volume"}}] }]' -f - \
    | kubectl patch --dry-run=client -o yaml --type json --patch '[{ "op": "replace", "path": "/spec/template/spec/containers/0/volumeMounts", "value": [{"mountPath": "/music", name: "music-volume"}] }]' -f - \
    | kubectl patch --dry-run=client -o yaml --type json --patch '[{ "op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["easy", "/music"] }]' -f - \
    | kubectl patch --dry-run=client -o yaml --type json --patch '[{ "op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["rsgain"] }]' -f - \
    | kubectl apply -f -

    | kubectl patch --dry-run=client -o yaml --type json --patch '[{ "op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {"limits": {"cpu": 1, "memory": "512Mi"}} }]' -f - \


    | kubectl patch --dry-run=client -o yaml --type json --patch '[{ "op": "replace", "path": "/spec/template/spec/containers/0/securityContext", "value": {"privileged": true} }]' -f - \
    | kubectl patch --dry-run=client -o yaml --type json --patch '[{ "op": "replace", "path": "/spec/template/spec/containers/0/securityContext", "value": {"runAsGroup": 5000, "runAsUser": 5000} }]' -f - \
    | kubectl patch --dry-run=client -o yaml --type json --patch '[{ "op": "replace", "path": "/spec/template/spec/securityContext", "value": {"fsGroup": 5000, "fsGroupChangePolicy": "OnRootMismatch"} }]' -f - \