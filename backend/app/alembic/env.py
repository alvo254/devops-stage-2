import os
from dotenv import load_dotenv
from logging.config import fileConfig
from urllib.parse import quote_plus

from sqlalchemy import engine_from_config, pool, create_engine, text
from sqlalchemy.exc import OperationalError

from alembic import context

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
# This line sets up loggers basically.
fileConfig(config.config_file_name)

# add your model's MetaData object here
# for 'autogenerate' support
from app.models import SQLModel  # noqa

target_metadata = SQLModel.metadata

load_dotenv()

print("Environment variables:")
print(f"POSTGRES_USER: {os.getenv('POSTGRES_USER')}")
print(f"POSTGRES_PASSWORD: {'*' * len(os.getenv('POSTGRES_PASSWORD', ''))}")  # Don't print the actual password
print(f"POSTGRES_SERVER: {os.getenv('POSTGRES_SERVER')}")
print(f"POSTGRES_PORT: {os.getenv('POSTGRES_PORT')}")
print(f"POSTGRES_DB: {os.getenv('POSTGRES_DB')}")

def get_url():
    user = os.getenv("POSTGRES_USER", "ubuntu")
    password = quote_plus(os.getenv("POSTGRES_PASSWORD", "twende@1357"))
    server = os.getenv("POSTGRES_SERVER", "34.228.146.120")
    port = os.getenv("POSTGRES_PORT", "5432")
    db = os.getenv("POSTGRES_DB", "fast_api")

    return f"postgresql+psycopg://{user}:{password}@{server}:{port}/{db}"

def test_connection():
    url = get_url()
    engine = create_engine(url)
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            print("Database connection successful!")
    except OperationalError as e:
        print(f"Error connecting to the database: {e}")
        raise

# Call this function before run_migrations_online()
test_connection()

def run_migrations_offline():
    """Run migrations in 'offline' mode."""
    url = get_url()
    context.configure(
        url=url, target_metadata=target_metadata, literal_binds=True, compare_type=True
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    """Run migrations in 'online' mode."""
    configuration = config.get_section(config.config_ini_section)
    configuration["sqlalchemy.url"] = get_url()
    
    try:
        connectable = engine_from_config(
            configuration,
            prefix="sqlalchemy.",
            poolclass=pool.NullPool,
        )

        with connectable.connect() as connection:
            context.configure(
                connection=connection, target_metadata=target_metadata, compare_type=True
            )

            with context.begin_transaction():
                context.run_migrations()
    except OperationalError as e:
        print(f"Error during migration: {e}")
        print("Please check your database configuration and ensure the database is accessible.")
        raise

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()