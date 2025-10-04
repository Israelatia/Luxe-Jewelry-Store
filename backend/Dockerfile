# Use official Python image
FROM python:3.12-slim

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for caching
COPY requirements.txt .

# Install Python dependencies
RUN python3 -m venv venv \
    && . venv/bin/activate \
    && pip install --upgrade pip \
    && pip install -r requirements.txt

# Copy application code
COPY . .

# Expose port (adjust according to your app)
EXPOSE 8000

# Set environment variables
ENV PATH="/app/venv/bin:$PATH"

# Run the app
CMD ["python3", "-m", "backend.main"]  # replace backend.main with your entrypoint
