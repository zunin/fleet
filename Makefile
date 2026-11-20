.DEFAULT_GOAL := help

# Discover explicit reseal targets from the Makefiles read so far.
reseal_targets := $(shell awk '/^reseal-[a-z0-9-]+:$$/ {sub(/:$$/, ""); print}' $(MAKEFILE_LIST))

.PHONY: help $(reseal_targets)
help:
	@printf '%s\n' 'Reseal targets (values are prompted for without echo; Enter keeps a value):' $(reseal_targets)

reseal-cifs-secret:
	@bash scripts/reseal.sh --manifest storage/cifs-secret.sealedsecret.yaml \
		--name cifs-secret --namespace longhorn --scope namespace-wide \
		--key CIFS_PASSWORD --key CIFS_USERNAME

reseal-cloudflare-api-token:
	@bash scripts/reseal.sh --manifest cert-manager/cloudflare-api-token.sealedsecret.yaml \
		--name cloudflare-api-token --namespace cert-manager --scope namespace-wide --key token

reseal-extraconfig:
	@bash scripts/reseal.sh --manifest chat/extraconfig.sealedsecret.yaml \
		--name extraconfig --namespace chat --scope namespace-wide --key client_secret --key signing_key

reseal-hister-config:
	@bash scripts/reseal.sh --manifest search/sealed-hister-config.yaml \
		--name hister-config --namespace search --scope strict --key ACCESS_TOKEN

reseal-lastfm-api:
	@bash scripts/reseal.sh --manifest music/lastfm-api.sealedsecret.yaml \
		--name lastfm-api --namespace music --scope namespace-wide --key apikey --key apisharedsecret

reseal-manyfold-secret-key:
	@bash scripts/reseal.sh --manifest 3dfiles/manyfold-secret-key.sealedsecret.yaml \
		--name manyfold-secret-key --namespace 3dfiles --scope namespace-wide --key manyfold-secret-key

reseal-nonfiction-index-auth:
	@bash scripts/reseal.sh --manifest books/nonfiction-index-auth.sealedsecret.yaml \
		--name nonfiction-index-auth --namespace books --scope strict --key kavita-key --key hister-token

reseal-registrationsharedsecret:
	@bash scripts/reseal.sh --manifest chat/registrationSharedSecret.sealedsecret.yaml \
		--name registrationsharedsecret --namespace chat --scope namespace-wide --key registrationsharedsecret

reseal-renovate-config:
	@bash scripts/reseal.sh --manifest renovate/sealed-renoveate-config-.yaml \
		--name renovate-config --namespace renovate --scope namespace-wide --key TokenSecret

reseal-spotify-client:
	@bash scripts/reseal.sh --manifest music/spotify-client.sealedsecret.yaml \
		--name spotify-client --namespace music --scope namespace-wide --key clientid --key clientsecret

reseal-synapse-postgres-password:
	@bash scripts/reseal.sh --manifest chat/sealed-synapse-postgres-password.yaml \
		--name synapse-postgres-password --namespace chat --scope strict --key password

reseal-synapse-redis-password:
	@bash scripts/reseal.sh --manifest chat/sealed-synapse-redis-password.yaml \
		--name synapse-redis-password --namespace chat --scope strict --key password

reseal-tunnel-credentials:
	@bash scripts/reseal.sh --manifest cloudflare-tunnel/sealed-tunnel-credentials.yaml \
		--name tunnel-credentials --namespace default --scope strict --key credentials.json

reseal-wallabag-parameters:
	@bash scripts/reseal.sh --manifest readlater/wallabag-parameters.sealedsecret.yaml \
		--name wallabag-parameters --namespace readlater --scope namespace-wide --key Secret

reseal-writefreely-config:
	@bash scripts/reseal.sh --manifest writings/sealed-writefreely-config.yaml \
		--name writefreely-config --namespace writings --scope strict --key ClientSecret
