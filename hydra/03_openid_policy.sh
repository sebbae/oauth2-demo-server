#!/bin/bash
HYDRA_VERSION=v0.10.10
CLUSTER_URL=https://hydra:4444
NETWORK=hydraguide
ROOT_CLIENT_USER=admin
ROOT_CLIENT_PASSWD=demo-password
SKIP_TLS_VERIFY=--skip-tls-verify

echo
echo "Creating policy for OpenID tokens"
echo
docker run --rm -it \
  -e CLUSTER_URL=$CLUSTER_URL \
  -e CLIENT_ID=$ROOT_CLIENT_USER \
  -e CLIENT_SECRET=$ROOT_CLIENT_PASSWD \
  --network $NETWORK \
  -p 9010:4445 \
  oryd/hydra:$HYDRA_VERSION \
  policies create $SKIP_TLS_VERIFY \
    --actions get \
    --description "Allow everyone to read the OpenID Connect ID Token public key" \
    --allow \
    --id openid-id_token-policy \
    --resources rn:hydra:keys:hydra.openid.id-token:public \
    --subjects "<.*>"

