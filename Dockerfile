# Use Hugging Face Text Embeddings Inference base image (amd64 for Lightsail)
ARG BUILDPLATFORM=linux/amd64
FROM --platform=${BUILDPLATFORM:-linux/amd64} ghcr.io/huggingface/text-embeddings-inference:cpu-1.8.1

# ===== Memory + thread optimizations =====
#ENV OMP_NUM_THREADS=1
#ENV KMP_AFFINITY=granularity=fine,compact,1,0
#ENV ORT_THREAD_POOL_SIZE=1

# ===== Authentication Configuration =====
# Expect API_KEY to be provided at runtime; do not bake defaults into the image
ENV API_KEY=""

# Copy pre-downloaded model files into the image
COPY data /data

# Expose port
EXPOSE 80

# ===== Healthcheck =====
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/health || exit 1
  
# ===== Authentication =====
# Do not echo API key during build

# ===== Final entrypoint =====
CMD ["--model-id", "/data", \
     "--pooling", "mean", \
     "--max-batch-tokens", "2048", \
     "--tokenization-workers", "2", \
     "--max-concurrent-requests", "2", \
     "--max-batch-requests", "2", \
     "--api-key", "$API_KEY", \
     "--auto-truncate", \
     "--port", "80"]
