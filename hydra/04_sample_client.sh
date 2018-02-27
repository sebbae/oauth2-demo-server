#!/bin/bash
HYDRA_VERSION=v0.10.10
CLUSTER_URL=https://hydra:4444
NETWORK=hydraguide
ROOT_CLIENT_USER=admin
ROOT_CLIENT_PASSWD=demo-password
SKIP_TLS_VERIFY=--skip-tls-verify

echo
echo "Creating consumer client"
echo
echo docker run --rm -it \
  -e CLUSTER_URL=$CLUSTER_URL \
  -e CLIENT_ID=$ROOT_CLIENT_USER \
  -e CLIENT_SECRET=$ROOT_CLIENT_PASSWD \
  --network $NETWORK \
  -p 9010:4445 \
  oryd/hydra:$HYDRA_VERSION \
    clients create $SKIP_TLS_VERIFY \
    --id some-consumer \
    --secret consumer-secret \
    --grant-types authorization_code,refresh_token,client_credentials,implicit \
    --response-types token,code,id_token \
    --allowed-scopes openid,offline,hydra.clients \
    --callbacks http://localhost:9010/callback


echo
echo "Test authorization workflow"
echo
docker run --rm -it \
	--network $NETWORK \
	-p 9010:4445 \
	oryd/hydra:$HYDRA_VERSION \
	token user $SKIP_TLS_VERIFY \
	--auth-url https://localhost:9000/oauth2/auth \
	--token-url https://hydra:4444/oauth2/token \
	--id some-consumer \
	--secret consumer-secret \
	--scopes openid,offline,hydra.clients \
	--redirect http://localhost:9010/callback
