# Backend - FastAPI with PostgreSQL

This directory contains the backend of the application built with FastAPI and a PostgreSQL database.

## Prerequisites

- Python 3.8 or higher
- Poetry (for dependency management)
- PostgreSQL (ensure the database server is running)

### Installing Poetry

To install Poetry, follow these steps:

```sh
curl -sSL https://install.python-poetry.org | python3 -
```

Add Poetry to your PATH (if not automatically added):

## Setup Instructions

1. **Navigate to the backend directory**:
    ```sh
    cd backend
    ```

2. **Install dependencies using Poetry**:
    ```sh
    poetry install
    ```

3. **Set up the database with the necessary tables**:
    ```sh
    poetry run bash ./prestart.sh
    ```

4. **Run the backend server**:
    ```sh
    poetry run uvicorn app.main:app --reload
    ```

5. **Update configuration**:
   Ensure you update the necessary configurations in the `.env` file, particularly the database configuration.

### Docker Compose

The `docker-compose.yml` file defines the following services:

- nginx: Reverse proxy
- backend: Main application service
- db: PostgreSQL database
- adminer: Database management tool

### Dockerfile

The Dockerfile for the backend service:

- Uses Python 3.9 as the base image
- Installs project dependencies
- Copies application files
- Sets up the wait-for-it script for database connection handling


Now, let's try to connect to the database using psql from the backend container
docker-compose exec backend psql -h db -U ubuntu -d ubuntu -c "SELECT 1"