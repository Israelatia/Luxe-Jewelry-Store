# infra/Dockerfile.app
FROM python:3.12-slim

WORKDIR /app

# Copy backend requirements
COPY backend/backend/src/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source code
COPY backend/backend/src/ .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]


