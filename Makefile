.DEFAULT_GOAL := help

export INPUT_DIR KUBE_CONTEXT

secrets := cifs-secret cloudflare-api-token extraconfig hister-config lastfm-api \
	manyfold-secret-key registrationsharedsecret renovate-config spotify-client \
	synapse-postgres-password synapse-redis-password tunnel-credentials \
	wallabag-parameters writefreely-config

# Each entry is: manifest namespace scope key [key ...]
secret.cifs-secret := storage/cifs-secret.sealedsecret.yaml longhorn namespace-wide CIFS_PASSWORD CIFS_USERNAME
secret.cloudflare-api-token := cert-manager/cloudflare-api-token.sealedsecret.yaml cert-manager namespace-wide token
secret.extraconfig := chat/extraconfig.sealedsecret.yaml chat namespace-wide client_secret signing_key
secret.hister-config := search/sealed-hister-config.yaml search strict ACCESS_TOKEN
secret.lastfm-api := music/lastfm-api.sealedsecret.yaml music namespace-wide apikey apisharedsecret
secret.manyfold-secret-key := 3dfiles/manyfold-secret-key.sealedsecret.yaml 3dfiles namespace-wide manyfold-secret-key
secret.registrationsharedsecret := chat/registrationSharedSecret.sealedsecret.yaml chat namespace-wide registrationsharedsecret
secret.renovate-config := renovate/sealed-renoveate-config-.yaml renovate namespace-wide TokenSecret
secret.spotify-client := music/spotify-client.sealedsecret.yaml music namespace-wide clientid clientsecret
secret.synapse-postgres-password := chat/sealed-synapse-postgres-password.yaml chat strict password
secret.synapse-redis-password := chat/sealed-synapse-redis-password.yaml chat strict password
secret.tunnel-credentials := cloudflare-tunnel/sealed-tunnel-credentials.yaml default strict credentials.json
secret.wallabag-parameters := readlater/wallabag-parameters.sealedsecret.yaml readlater namespace-wide Secret
secret.writefreely-config := writings/sealed-writefreely-config.yaml writings strict ClientSecret

reseal_targets := $(addprefix reseal-,$(secrets))
help_targets := $(addprefix help-,$(secrets))

.PHONY: help $(reseal_targets) $(help_targets)
help:
	@printf '%s\n' 'Reseal targets (run make help-<name> for details):' $(reseal_targets)

$(help_targets): help-%:
	@printf '%s\n' 'Usage: make reseal-$* [INPUT_DIR=/path/to/values] [KUBE_CONTEXT=context]' \
		'Manifest: $(word 1,$(secret.$*))' 'Namespace: $(word 2,$(secret.$*))' \
		'Required keys: $(wordlist 4,999,$(secret.$*))' \
		'Omit INPUT_DIR for hidden prompts; press Enter to keep a value. With INPUT_DIR, provide one file per key.' \
		'Omit KUBE_CONTEXT to use the current kubectl context.'

$(reseal_targets): reseal-%:
	@bash scripts/reseal.sh '$(word 1,$(secret.$*))' '$*' $(wordlist 2,999,$(secret.$*))
