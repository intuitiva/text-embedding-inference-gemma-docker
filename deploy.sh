#!/bin/bash

set -euo pipefail

# Load .env if present (for local secrets). Never commit .env to git.
if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

# Get configuration from deployment.json
region="us-east-1"
service_name="text-embeddings-gemma-q4f16"
image_name="text-embeddings-gemma-q4f16"

# Require API_KEY to be set via environment or .env
if [ -z "${API_KEY:-}" ]; then
  echo "Error: API_KEY is not set. Set it in your environment or in .env"
  exit 1
fi

#build the docker image
docker build -t $image_name:latest .

# Push the container image and capture the response
push_response=$(aws lightsail push-container-image --region $region --service-name $service_name --label latest --image $image_name:latest)

# Extract the image reference from the response
lightsail_image=$(echo "$push_response" | grep -o 'Refer to this image as ":[^"]*"' | sed 's/Refer to this image as "\([^"]*\)"/\1/')

# Save the image reference to a variable and optionally to a file
echo "Lightsail image reference: $lightsail_image"

# Update deployment.json with the new image reference
# Remove the leading colon from the image reference for deployment.json
clean_image=$(echo "$lightsail_image" | sed 's/^://')

cat > deployment.json <<EOL
{
  "text-embeddings-gemma-q4f16": {
    "image": "$clean_image",
    "ports": {
      "80": "HTTP"
    },
    "environment": {
      "API_KEY": "$API_KEY"
    }
  }
}
EOL

echo "Updated deployment.json with image: $clean_image"

# Create the container service deployment
deployment_response=$(aws lightsail create-container-service-deployment \
  --service-name $service_name \
  --containers file://deployment.json \
  --public-endpoint file://public-endpoint.json)

# Display the response
echo "Deployment response: $deployment_response"
