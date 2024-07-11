# Use an official Python runtime as a parent image
FROM python:3.10

WORKDIR /app

# Install Poetry
RUN pip install poetry

# Install PostgreSQL client
RUN apt-get update && apt-get install -y postgresql-client netcat-openbsd

# Copy only requirements to cache them in docker layer
COPY poetry.lock pyproject.toml /app/

#Project initialization:
RUN poetry config virtualenvs.create true \
  && poetry install --no-interaction --no-ansi \
  && poetry add alembic

# Copy project
COPY . /app

# Make the script executable
RUN chmod +x /app/prestart.sh

# Create a new script to wait for the database
RUN echo '#!/bin/bash\n\
echo "Waiting for database..."\n\
while ! nc -z db 5432; do\n\
  sleep 1\n\
done\n\
echo "Database is ready!"\n\
exec "$@"' > /app/wait.sh && chmod +x /app/wait.sh

# Use the new script to wait for the database, then run prestart.sh and start the application
# Set the PYTHONPATH and start the application
CMD ["/bin/bash", "-c", "export PYTHONPATH=/app && /app/wait.sh /app/prestart.sh && poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000"]