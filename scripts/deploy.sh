#!/bin/bash
set -e

# ================================================
#   Gym Management System - Deployment Script
# ================================================
# Idempotent: can be run multiple times safely
# - Stops containers WITHOUT destroying volumes
# - Pulls latest images from GHCR
# - Restarts the full application stack

IMAGE_TAG="${GITHUB_SHA:-latest}"
OWNER="${OWNER:-kaz5273}"
OWNER=$(echo "$OWNER" | tr '[:upper:]' '[:lower:]')

echo "================================================"
echo "  Gym Management System - Deployment Script"
echo "================================================"
echo "  Image tag : $IMAGE_TAG"
echo "  Owner     : $OWNER"
echo ""

# Step 1: Stop running containers (preserve volumes)
echo "[1/3] Stopping running containers..."
docker compose down
echo "  Containers stopped (volumes preserved)"
echo ""

# Step 2: Pull latest images from GHCR
echo "[2/3] Pulling images from GHCR..."
docker pull "ghcr.io/$OWNER/cloudnative-backend:$IMAGE_TAG"
docker pull "ghcr.io/$OWNER/cloudnative-frontend:$IMAGE_TAG"
echo "  Images pulled"
echo ""

# Step 3: Start the full stack using GHCR images directly
echo "[3/3] Starting application..."
export BACKEND_IMAGE="ghcr.io/$OWNER/cloudnative-backend:$IMAGE_TAG"
export FRONTEND_IMAGE="ghcr.io/$OWNER/cloudnative-frontend:$IMAGE_TAG"
docker compose up -d
echo ""

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 10

# Verify deployment
echo "Deployment status:"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Check all services are running
FAILED=$(docker compose ps --format "{{.Name}}|{{.State}}" | grep -v "running" || true)
if [ -n "$FAILED" ]; then
  echo "ERROR: Some services failed to start:"
  echo "$FAILED"
  echo "Check logs: docker compose logs -f"
  exit 1
fi

echo "================================================"
echo "  Deployment completed successfully!"
echo "================================================"
echo ""
echo "Application URLs:"
echo "  Frontend : http://localhost:8080"
echo "  Backend  : http://localhost:3000"
echo ""
