#!/bin/bash

# Export PYTHONPATH to include the app directory
export PYTHONPATH=/app

# Run the backend pre-start script
poetry run python /app/app/backend_pre_start.py

# Run Alembic migrations
poetry run alembic upgrade head

# Run the initial data setup script
poetry run python /app/app/initial_data.py

# Start the FastAPI application
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000