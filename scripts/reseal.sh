#!/usr/bin/env bash
set -euo pipefail

fail() { printf 'Reseal failed: %s\n' "$*" >&2; exit 1; }

manifest='' name='' namespace='' scope=''
keys=()
while (($#)); do
    case "$1" in
        --manifest|--name|--namespace|--scope|--key)
            [[ $# -ge 2 && -n $2 && $2 != --* ]] || fail "Missing value for $1"
            case "$1" in
                --manifest) manifest=$2 ;;
                --name) name=$2 ;;
                --namespace) namespace=$2 ;;
                --scope) scope=$2 ;;
                --key) keys+=("$2") ;;
            esac
            shift 2
            ;;
        *) fail "Unknown option: $1" ;;
    esac
done

[[ -n $manifest && -n $name && -n $namespace && -n $scope && ${#keys[@]} -gt 0 ]] \
    || fail 'Specify --manifest, --name, --namespace, --scope, and at least one --key'

content=$(cat "$manifest")
exec 3<>/dev/tty || fail 'Hidden prompts require a terminal'
changed=false

for key in "${keys[@]}"; do
    IFS= read -r -s -p "New value for $key (Enter to keep): " value <&3 >&3 \
        || fail 'Input cancelled; manifest unchanged'
    printf '\n' >&3
    [[ -n $value ]] || continue

    ciphertext=$(printf '%s' "$value" | kubeseal --raw \
        --namespace "$namespace" --name "$name" --scope "$scope")
    unset value
    content=$(printf '%s\n' "$content" | KEY="$key" CIPHERTEXT="$ciphertext" \
        yq '.spec.encryptedData[strenv(KEY)] = strenv(CIPHERTEXT)')
    changed=true
done

if [[ $changed == false ]]; then
    printf 'No changes.\n'
    exit 0
fi

printf '%s\n' "$content" | kubeseal --validate >/dev/null
printf '%s\n' "$content" > "$manifest"
