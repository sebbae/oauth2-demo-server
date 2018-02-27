#!/bin/bash
HYDRA_VERSION=v0.10.10
CLUSTER_URL=https://hydra:4444
NETWORK=hydraguide
ROOT_CLIENT_USER=admin
ROOT_CLIENT_PASSWD=demo-password
CONSENT_CLIENT_ID=consent-app
CONSENT_CLIENT_SECRET=consent-secret
SKIP_TLS_VERIFY=--skip-tls-verify

CONSENT_CONTAINER=hydra-consent

echo
echo "Creating client consent app client \"$CONSENT_CLIENT_ID\""
echo
docker run --rm -it \
  -e CLUSTER_URL=$CLUSTER_URL \
  -e CLIENT_ID=$ROOT_CLIENT_USER \
  -e CLIENT_SECRET=$ROOT_CLIENT_PASSWD \
  --network $NETWORK \
  -p 9010:4445 \
  oryd/hydra:$HYDRA_VERSION \
	clients create \
	$SKIP_TLS_VERIFY \
	--id $CONSENT_CLIENT_ID \
	--secret $CONSENT_CLIENT_SECRET \
	--name "Consent App Client" \
	--grant-types client_credentials \
	--response-types token \
	--allowed-scopes hydra.consent

echo
echo "Creating policy for consent app client \"$CONSENT_CLIENT_ID\""
echo
docker run --rm -it \
  -e CLUSTER_URL=$CLUSTER_URL \
  -e CLIENT_ID=$ROOT_CLIENT_USER \
  -e CLIENT_SECRET=$ROOT_CLIENT_PASSWD \
  --network $NETWORK \
  -p 9010:4445 \
  oryd/hydra:$HYDRA_VERSION \
    policies create \
	$SKIP_TLS_VERIFY \
	--actions get,accept,reject \
	--description "Allow consent-app to manage OAuth2 consent requests." \
	--allow \
	--id ${CONSENT_CLIENT_ID}-policy \
	--resources "rn:hydra:oauth2:consent:requests:<.*>" \
	--subjects $CONSENT_CLIENT_ID

echo
echo "Starting consent app $CONSENT_CONTAINER"
echo
docker run -d \
	--name $CONSENT_CONTAINER \
	-p 9020:3000 \
	--network $NETWORK \
	-e HYDRA_CLIENT_ID=$CONSENT_CLIENT_ID \
	-e HYDRA_CLIENT_SECRET=$CONSENT_CLIENT_SECRET \
	-e HYDRA_URL=$CLUSTER_URL \
	-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
	oryd/hydra-consent-app-express

