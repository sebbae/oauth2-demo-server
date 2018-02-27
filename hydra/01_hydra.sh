#!/bin/bash
SYSTEM_SECRET=this_needs_to_be_the_same_always_and_also_very_$3cuR3-._
ROOT_CLIENT_USER=admin
ROOT_CLIENT_PASSWD=demo-password

ISSUER=https://localhost:9000/
CONSENT_URL=http://localhost:9020/consent

NETWORK=hydraguide

HYDRA_CONTAINER=hydra
HYDRA_VERSION=v0.10.10

POSTGRES_CONTAINER=hydra-postgres
POSTGRES_USER=hydra
POSTGRES_PASSWD=secret
POSTGRES_VERSION=9.6

echo
echo "Creating docker network $NETWORK"
echo
docker network create $NETWORK

echo
echo "Starting PostgreSQL container $POSTGRES_CONTAINER ($POSTGRES_VERSION)"
echo
docker run \
	--network $NETWORK \
	--name $POSTGRES_CONTAINER \
	-e POSTGRES_USER=$POSTGRES_USER \
	-e POSTGRES_PASSWORD=$POSTGRES_PASSWD \
	-e POSTGRES_DB=hydra \
	-d postgres:$POSTGRES_VERSION

echo
echo "Exporting PostgreSQL database URL"
echo
export DATABASE_URL="postgres://$POSTGRES_USER:$POSTGRES_PASSWD@$POSTGRES_CONTAINER:5432/hydra?sslmode=disable"

echo
echo "Exporting system secret"
echo
export SYSTEM_SECRET="$SYSTEM_SECRET" 

echo
echo "Pulling hydra version $HYDRA_VERSION"
echo
docker pull oryd/hydra:$HYDRA_VERSION

echo
echo "Migrating/initializing database"
echo
docker run -it --rm \
	--network $NETWORK \
	oryd/hydra:$HYDRA_VERSION \
	migrate sql $DATABASE_URL

echo
echo "Starting hydra container $HYDRA_CONTAINER ($HYDRA_VERSION)"
echo
docker run -d \
	--name $HYDRA_CONTAINER \
	--network $NETWORK \
	-p 9000:4444 \
	-e SYSTEM_SECRET=$SYSTEM_SECRET \
	-e DATABASE_URL=$DATABASE_URL \
	-e ISSUER=$ISSUER \
	-e CONSENT_URL=$CONSENT_URL \
	-e FORCE_ROOT_CLIENT_CREDENTIALS=$ROOT_CLIENT_USER:$ROOT_CLIENT_PASSWD \
	oryd/hydra:$HYDRA_VERSION

