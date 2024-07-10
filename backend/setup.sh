#!/bin/bash
set -e

echo "Starting database setup..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO
    \$do\$
    BEGIN
        IF NOT EXISTS (
            SELECT FROM pg_catalog.pg_roles WHERE rolname = 'ubuntu'
        ) THEN
            CREATE USER ubuntu WITH PASSWORD 'twende@1357';
        END IF;
    END
    \$do\$;

    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO ubuntu;
EOSQL

echo "Database setup completed successfully."