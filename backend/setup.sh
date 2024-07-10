#!/bin/bash
set -e

echo "Starting database setup..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create the ubuntu user if it doesn't exist
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

    -- Create the ubuntu database if it doesn't exist
    CREATE DATABASE ubuntu;

    -- Grant privileges to the ubuntu user on the ubuntu database
    GRANT ALL PRIVILEGES ON DATABASE ubuntu TO ubuntu;

    -- Connect to the ubuntu database
    \c ubuntu

    -- Grant privileges on all tables in the public schema to the ubuntu user
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ubuntu;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ubuntu;
    GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO ubuntu;

    -- Allow ubuntu user to create new objects in the public schema
    GRANT CREATE ON SCHEMA public TO ubuntu;
EOSQL

echo "Database setup completed successfully."