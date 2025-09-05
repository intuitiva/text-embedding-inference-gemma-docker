#!/bin/bash

# Get configuration from deployment.json
region="us-east-1"
service_name="text-embeddings-gemma"
image_name="text-embeddings-gemma"

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
  "text-embeddings-gemma": {
    "image": "$clean_image",
    "ports": {
      "80": "HTTPS"
    },
    "environment": { "RUST_LOG": "info" }
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
