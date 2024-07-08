#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER ubuntu WITH PASSWORD 'twende@1357';
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO ubuntu;
EOSQL