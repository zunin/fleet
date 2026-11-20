#!/usr/bin/env bash
set -euo pipefail

fail() { printf 'Reseal failed: %s\n' "$*" >&2; exit 1; }

manifest=$1 name=$2 namespace=$3 scope=$4
shift 4
keys=("$@")
for key in "${keys[@]}"; do
    [[ $key =~ ^[A-Za-z0-9._-]+$ ]] || fail 'Invalid registered key'
done

identity() {
    NAME=$name NAMESPACE=$namespace yq -e '
        .kind == "SealedSecret" and .metadata.name == strenv(NAME)
        and .metadata.namespace == strenv(NAMESPACE)
    ' "$1" >/dev/null
}

# Force raw scalar output for both YAML manifests and kubeseal's JSON output.
key_list() { yq -e -o=yaml -r '.spec.encryptedData | keys | .[]' "$1" | LC_ALL=C sort; }
expected_keys() { printf '%s\n' "$@" | LC_ALL=C sort; }

identity "$manifest" || fail 'Manifest identity does not match registration'
actual_keys=$(key_list "$manifest") || fail 'Cannot read manifest keys'
[[ $actual_keys == "$(expected_keys "${keys[@]}")" ]] || fail 'Manifest keys do not match registration'
for candidate in namespace-wide cluster-wide; do
    annotation=$(ANNOTATION="sealedsecrets.bitnami.com/$candidate" yq '.metadata.annotations[strenv(ANNOTATION)]' "$manifest")
    if [[ $candidate == "$scope" ]]; then
        [[ $annotation == true ]] || fail 'Manifest scope does not match registration'
    else
        [[ $annotation != true ]] || fail 'Manifest scope does not match registration'
    fi
done

context=${KUBE_CONTEXT:-}
if [[ -z $context ]]; then
    context=$(kubectl config current-context) || fail 'Select a kubectl context or set KUBE_CONTEXT'
    [[ -n $context ]] || fail 'Select a kubectl context or set KUBE_CONTEXT'
fi
printf 'Resealing %s/%s in context %s\n' "$namespace" "$name" "$context" >&2

if [[ -n ${INPUT_DIR:-} ]]; then
    inputs=$(cd -- "$INPUT_DIR" && pwd -P) || fail 'Cannot open INPUT_DIR'
    repo=$(pwd -P)
    case "$inputs/" in "$repo/"*) fail 'Keep plaintext input files outside the repository' ;; esac
    shopt -s nullglob dotglob
    files=("$inputs"/*)
    [[ ${#files[@]} == ${#keys[@]} ]] || fail "INPUT_DIR must contain exactly these files: ${keys[*]}"
    from_files=()
    for key in "${keys[@]}"; do
        [[ -f $inputs/$key && ! -L $inputs/$key ]] || fail "Missing regular file for $key"
        from_files+=("--from-file=$key=$inputs/$key")
    done
    selected=("${keys[@]}")
    secret=$(kubectl --context "$context" --namespace "$namespace" create secret generic "$name" \
        --dry-run=client -o json "${from_files[@]}" 2>/dev/null) || fail 'kubectl could not build the Secret'
else
    exec 3<>/dev/tty || fail 'Hidden prompts require a terminal; use INPUT_DIR instead'
    trap 'fail "Input cancelled; manifest unchanged"' INT
    selected=()
    entries=()
    for key in "${keys[@]}"; do
        printf 'Enter new value for %s (Enter to keep): ' "$key" >&3
        if ! IFS= read -r -s value <&3; then
            printf '\n' >&3
            fail 'Input cancelled; manifest unchanged'
        fi
        printf '\n' >&3
        [[ -n $value ]] || continue
        encoded=$(printf '%s' "$value" | base64 | tr -d '\r\n')
        unset value
        selected+=("$key")
        entries+=("\"$key\":\"$encoded\"")
    done
    exec 3>&-
    if [[ ${#entries[@]} == 0 ]]; then
        printf 'No changes.\n'
        exit 0
    fi
    data=$(IFS=,; printf '%s' "${entries[*]}")
    secret=$(printf '{"apiVersion":"v1","kind":"Secret","metadata":{"name":"%s","namespace":"%s"},"type":"Opaque","data":{%s}}' \
        "$name" "$namespace" "$data")
    unset data encoded entries
fi

seal=(kubeseal --context "$context")
work=$(mktemp -d "$(dirname -- "$manifest")/.reseal.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
printf '%s' "$secret" | "${seal[@]}" --scope "$scope" --format json >"$work/sealed.json" 2>/dev/null \
    || fail 'kubeseal could not encrypt the values'
unset secret
identity "$work/sealed.json" || fail 'Generated SealedSecret has an unexpected identity'
actual_keys=$(key_list "$work/sealed.json") || fail 'Cannot read generated ciphertext keys'
[[ $actual_keys == "$(expected_keys "${selected[@]}")" ]] || fail 'Generated ciphertext has an unexpected key set'

cp -p -- "$manifest" "$work/manifest.yaml"
# JSON input carries flow style; reset it only on the merged ciphertext map.
SEALED="$work/sealed.json" yq -o=yaml '
    .spec.encryptedData *= load(strenv(SEALED)).spec.encryptedData |
    (.spec.encryptedData | ...) style = ""
' "$manifest" >"$work/manifest.yaml"
"${seal[@]}" --validate <"$work/manifest.yaml" >/dev/null || fail 'The complete manifest did not validate'
mv -- "$work/manifest.yaml" "$manifest"
printf 'Updated %s; review and commit the ciphertext diff.\n' "$manifest"
