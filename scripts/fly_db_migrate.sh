#!/usr/bin/env bash
set -x
set -eo pipefail

if ! [ -x "$(command -v psql)" ]; then
    echo >&2 "Error: psql is not installed."
    exit 1
fi

if ! [ -x "$(command -v sqlx)" ]; then
    echo >&2 "Error: sqlx is not installed."
    echo >&2 "Use:"
    echo >&2 " cargo install --version='~0.6' sqlx-cli \
    --no-default-features --features rustls,postgres"
    echo >&2 "to install it."
    exit 1
fi

if ! [ -x "$(command -v fly)" ]; then
    echo >&2 "Error: fly is not installed."
    echo >&2 "Use:"
    echo >&2 "curl -L https://fly.io/install.sh | sh"
    exit 1
fi

if [ -z "${FLY_DB_PASSWORD}" ]
  then
    echo "ENV FLY_DB_PASSWORD not found, fly database password"
    exit 1
fi

if [ -z "${FLY_DB_APP}" ]
  then
    echo "ENV FLY_DB_APP not found, fly database app name"
    exit 1
fi

DB_USER="${POSTGRES_USER:=$FLY_DB_USERNAME}"

DB_PASSWORD="${POSTGRES_PASSWORD:=$FLY_DB_PASSWORD}"

DB_NAME="${POSTGRES_DB:=$FLY_DB_NAME}"

DB_PORT="${DB_PORT:=$FLY_DB_PORT}"

flyctl proxy $DB_PORT -a $FLY_DB_APP &
DB_PROXY_PID=$!

# Keeping pinging Postgres until it's ready to accept commands
export PGPASSWORD="${DB_PASSWORD}"
until psql -h "localhost" -U "${DB_USER}" -p "${DB_PORT}" -d "postgres" -c "\q"; do
    >&2 echo "Postgres is still unavailable - sleeping"
    sleep 1
done

>&2 echo "Postgres is up and running on port ${DB_PORT} - running migrations now!"

DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}
export DATABASE_URL
sqlx database create
sqlx migrate run
kill $DB_PROXY_PID

>&2 echo "Postgres has been migrated, ready to go!"
