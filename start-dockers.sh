#!/bin/bash

# If we do not find a postgres volume for persistent data, create it now.
if ! docker volume inspect pgdata ; then
	echo "Creating docker volume for pgdata..."
	docker volume create --name=pgdata
	echo "Creating docker volume for pgdata... done."
fi

echo "Starting postgres docker."
docker run -d \
	--rm \
	--name postgres \
	-p 5432:5432 \
	 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
	-d \
	-v pgdata:/var/lib/postgresql/data \
	postgres:16

# Migrate / create database
# mix ecto.create
# mix ecto.migrate