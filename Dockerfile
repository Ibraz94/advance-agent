# Use Python 3.11 slim as base image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 chainlit
RUN mkdir -p /app && chown chainlit:chainlit /app

# Set the working directory
WORKDIR /app

# Create necessary directories with proper permissions
RUN mkdir -p /app/.files /app/.chainlit \
    && chown -R chainlit:chainlit /app/.files /app/.chainlit

# Copy requirements first to leverage Docker cache
COPY --chown=chainlit:chainlit requirements.txt .

# Switch to non-root user
USER chainlit

# Install Python dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# Copy the rest of the application
COPY --chown=chainlit:chainlit . .

# Expose the port Chainlit runs on
EXPOSE 8000

# Make sure the local user directory is in PATH
ENV PATH="/home/chainlit/.local/bin:${PATH}"

# Start the Chainlit app
CMD ["chainlit", "run", "main.py", "--host", "0.0.0.0", "--port", "8000"]
