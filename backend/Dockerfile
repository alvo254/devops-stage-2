# Use an official Python runtime as a parent image
FROM python:3.10

WORKDIR /app

# Install Poetry
RUN pip install poetry

# Copy only requirements to cache them in docker layer
COPY poetry.lock pyproject.toml /app/

# Project initialization:
RUN poetry config virtualenvs.create false \
  && poetry install --no-interaction --no-ansi

# Copy project
COPY . /app

# Make the script executable
RUN chmod +x /app/prestart.sh

# Run prestart.sh and then start the application
CMD ["/bin/bash", "-c", "/app/prestart.sh && uvicorn app.main:app --host 0.0.0.0 --port 8000"]