# Text Embeddings Inference - Gemma Docker Container

This repository contains a Docker container for running Gemma text embeddings inference optimized for AWS Lightsail with under 1GB RAM usage.

## Quick Start

### Download the model Data

Go to exactly this link: [hugginface](https://huggingface.co/onnx-community/embeddinggemma-300m-ONNX/tree/main/onnx) 

and download "model_q4.onnx_data"

and store it in data/onnx/

### Build the image
```bash
# Build the image
docker build -t text-embeddings-gemma .
```

### Running Locally
```bash
docker run --platform linux/amd64 -p 8080:80 text-embeddings-gemma
```

## AWS Lightsail Deployment

### Prerequisites
- AWS CLI installed and configured
- Docker installed
- Lightsail container service created

### Step 1: Build and Tag Image
```bash
# Build the image
docker build -t text-embeddings-gemma:latest .

# Tag for Lightsail registry
docker tag text-embeddings-gemma:latest your-registry-uri/text-embeddings-gemma:latest
```

### Step 2: Push to Lightsail Container Registry
```bash
# Register container image with Lightsail
aws lightsail register-container-image \
  --service-name text-embeddings-gemma \
  --label text-embeddings-gemma \
  --image text-embeddings-gemma:latest
```

### Step 3: Deploy to Lightsail
Create deployment configuration files:

**deployment.json**
```json
{
  "text-embeddings-gemma": {
    "image": "your-registry-uri/text-embeddings-gemma:latest",
    "ports": {
      "80": "HTTPS"
    }
  }
}
```

**public-endpoint.json**
```json
{
  "containerName": "text-embeddings-gemma",
  "containerPort": 80,
  "healthCheck": {
    "healthyThreshold": 2,
    "unhealthyThreshold": 2,
    "timeoutSeconds": 5,
    "intervalSeconds": 30,
    "path": "/health",
    "successCodes": "200"
  }
}
```

Deploy:
```bash
aws lightsail create-container-service-deployment \
  --service-name your-service-name \
  --containers file://deployment.json \
  --public-endpoint file://public-endpoint.json
```

### Step 4: Verify Deployment
```bash
# Get public endpoint
aws lightsail get-container-services --service-name your-service-name

# Test the endpoint
curl http://YOUR_PUBLIC_ENDPOINT/health

# Test embeddings
curl -X POST http://YOUR_PUBLIC_ENDPOINT/embed \
  -H "Content-Type: application/json" \
  -d '{"inputs": ["Hello world"]}'
```

## Memory Optimization
This container is optimized for under 1GB RAM usage with:
- Limited thread counts
- Reduced batch processing size
- Optimized ONNX runtime settings

## API Usage
- Health check: GET /health
- Generate embeddings: POST /embed
