# --- STAGE 1: BUILD ---
FROM python:3.12-slim as builder

# Install build dependencies for Python packages and the K3s installer dependencies (curl)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    musl-dev \
    libffi-dev \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade -r requirements.txt

# Download the K3s binary and the entrypoint script
RUN curl -sfL https://get.k3s.io -o /usr/local/bin/k3s && chmod +x /usr/local/bin/k3s

# --- STAGE 2: RUNTIME ---
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PORT 8000 

WORKDIR /app

# Copy Python dependencies from the builder stage
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# Copy the application code
COPY main.py .

# Copy the K3s binary
COPY --from=builder /usr/local/bin/k3s /usr/local/bin/k3s

# Copy and set the entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]