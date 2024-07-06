FROM python:3.10-slim

# Install Poetry
RUN pip install --no-cache-dir poetry

# Set the working directory in the container
WORKDIR /app

# Copy the pyproject.toml and poetry.lock files
COPY pyproject.toml poetry.lock /app/

# Install the dependencies
RUN poetry install --no-root

# Copy the rest of the application code
COPY . /app

# Copy the start script
COPY prestart.sh /app/prestart.sh

# Give execution permission to the start script
RUN chmod +x /app/prestart.sh

# Make port 8000 available to the world outside this container
EXPOSE 8000

# Run the start script
CMD ["/app/prestart.sh"]