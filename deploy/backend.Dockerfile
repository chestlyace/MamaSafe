# MamaSafe FastAPI backend
# Build: docker build -f deploy/backend.Dockerfile -t mamasafe-backend .
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        libgomp1 \
        curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies first for better layer caching
COPY backend/requirements.txt requirements.txt
RUN pip install --upgrade pip && pip install -r requirements.txt

# Application code
COPY backend/app ./app
COPY backend/model ./model

# Non-root user
RUN useradd --create-home --uid 1000 appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# Wait briefly for the database, then start. Tables and light migrations
# are created on startup via app.database.create_tables().
CMD ["sh", "-c", "sleep 3 && exec uvicorn app.main:app --host 0.0.0.0 --port 8000"]
