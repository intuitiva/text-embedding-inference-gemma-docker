# Text Embeddings Inference - Gemma Docker Container

This repository contains a Docker container for running Gemma text embeddings inference optimized for AWS Lightsail with under 1GB RAM usage with the smallest possible memory footprint.

These are the test that I have done before to make this work:

| embeddings runner | model | format | quantization | memory in lightsail container | response time |
|---|---|---|---|---|
| [llamafiler](https://github.com/intuitiva/llamafiler-embeddings-docker) | [Qwen3-embedding-0.6B](https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF) | GGUF | 8bit | 0.95GB | 3,600ms|
| [text-embedding-inference](https://github.com/intuitiva/text-embedding-inference-qwen3-docker) | [Qwen3-embedding-0.6B](https://huggingface.co/janni-t/qwen3-embedding-0.6b-int8-tei-onnx) | ONNX | 8bit | 1.1GB | 550ms |
| text-embedding-inference | [EmbeddingGemma-300M](https://huggingface.co/onnx-community/embeddinggemma-300m-ONNX) | ONNX | 8bit | 0.54GB | 450ms |

> Note: I also tried [Infinity](https://github.com/michaelfeil/infinity) but they had some problems with the qwen models https://github.com/michaelfeil/infinity/issues/611 

## STEP 0: Download the model Data (onnx_data) Q4FP16

Go to exactly this link: [hugginface](https://huggingface.co/onnx-community/embeddinggemma-300m-ONNX/tree/main/onnx) 

and download "model_q4fp16.onnx_data"

and store it in data/onnx/

## RUN LOCALLY

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

### Automated deploy

```bash
# first add permissions to execute to the deploy.sh script
chmod 777 deploy.sh
./deploy.sh
```

### Manual Deploy Step 1: Build and Tag Image
```bash
# Build the image
docker build -t text-embeddings-gemma:latest .

# Tag for Lightsail registry
docker tag text-embeddings-gemma:latest your-registry-uri/text-embeddings-gemma:latest
```

### Manual Deploy Step 2: Push to Lightsail Container Registry
```bash
# Register container image with Lightsail
aws lightsail register-container-image \
  --service-name text-embeddings-gemma \
  --label text-embeddings-gemma \
  --image text-embeddings-gemma:latest
```

### Manual Deploy Step 3: Deploy to Lightsail
Create deployment configuration files:

**deployment.json**
```json
{
  "text-embeddings-gemma": {
    "image": "your-registry-uri/text-embeddings-gemma:latest",
    "ports": {
      "80": "HTTP"
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

### Manual Deploy Step 4: Verify Deployment
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