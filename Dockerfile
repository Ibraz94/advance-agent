# Use Python 3.11 slim as base image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 chainlit
RUN mkdir -p /app && chown chainlit:chainlit /app
USER chainlit

# Set the working directory
WORKDIR /app

# Create necessary directories
RUN mkdir -p /app/.files && \
    mkdir -p /app/.chainlit && \
    chown -R chainlit:chainlit /app/.files /app/.chainlit

# Copy requirements first to leverage Docker cache
COPY --chown=chainlit:chainlit requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY --chown=chainlit:chainlit . .

# Expose the port Chainlit runs on
EXPOSE 8000

# Start the Chainlit app
CMD ["chainlit", "run", "main.py", "--host", "0.0.0.0", "--port", "8000"]
