#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER ubuntu WITH PASSWORD 'twende@1357';
    CREATE DATABASE fast_api;
    GRANT ALL PRIVILEGES ON DATABASE fast_api TO ubuntu;
EOSQL