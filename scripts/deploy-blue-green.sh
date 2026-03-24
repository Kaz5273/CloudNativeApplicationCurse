#!/bin/bash
set -e

# ================================================
#   Gym Management System - Blue/Green Deployment
# ================================================
# Logique :
#   1. Detecte la couleur active (blue ou green)
#   2. Deploie la nouvelle version sur la couleur inactive
#   3. Bascule le reverse proxy vers la nouvelle couleur
#   4. L'ancienne couleur reste active pour un rollback rapide

IMAGE_TAG="${GITHUB_SHA:-latest}"
OWNER="${OWNER:-kaz5273}"
OWNER=$(echo "$OWNER" | tr '[:upper:]' '[:lower:]')

WORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ACTIVE_CONF="$WORK_DIR/nginx/conf.d/active.conf"

echo "================================================"
echo "  Blue/Green Deployment"
echo "================================================"
echo "  Image tag : $IMAGE_TAG"
echo "  Owner     : $OWNER"
echo ""

# ── Etape 1 : Detecter la couleur active ────────────────────────
echo "[1/5] Detection de la couleur active..."

if docker ps --format "{{.Names}}" | grep -q "gym_backend_blue"; then
    CURRENT_COLOR="blue"
    NEW_COLOR="green"
else
    CURRENT_COLOR="green"
    NEW_COLOR="blue"
fi

echo "  Couleur active    : $CURRENT_COLOR"
echo "  Couleur cible     : $NEW_COLOR"
echo ""

# ── Etape 2 : Demarrer l'infrastructure de base si necessaire ───
echo "[2/5] Verification de l'infrastructure de base..."

if ! docker ps --format "{{.Names}}" | grep -q "gym_proxy"; then
    echo "  Demarrage de l'infrastructure (postgres + proxy)..."
    docker compose -f "$WORK_DIR/docker-compose.base.yml" up -d
    echo "  Attente que Postgres soit pret..."
    sleep 15
else
    echo "  Infrastructure deja en cours d'execution"
fi
echo ""

# ── Etape 3 : Puller et deployer la nouvelle couleur ────────────
echo "[3/5] Deploiement de la version $NEW_COLOR..."

export BACKEND_IMAGE="ghcr.io/$OWNER/cloudnative-backend:$IMAGE_TAG"
export FRONTEND_IMAGE="ghcr.io/$OWNER/cloudnative-frontend:$IMAGE_TAG"

echo "  Pull backend  : $BACKEND_IMAGE"
docker pull "$BACKEND_IMAGE"

echo "  Pull frontend : $FRONTEND_IMAGE"
docker pull "$FRONTEND_IMAGE"

echo "  Demarrage des conteneurs $NEW_COLOR..."
docker compose \
    -f "$WORK_DIR/docker-compose.base.yml" \
    -f "$WORK_DIR/docker-compose.$NEW_COLOR.yml" \
    up -d --no-recreate

echo ""

# ── Etape 4 : Attendre que la nouvelle couleur soit prete ───────
echo "[4/5] Attente que $NEW_COLOR soit operationnel..."

BACKEND_CONTAINER="gym_backend_$NEW_COLOR"
MAX_RETRIES=15
RETRY=0

until [ "$(docker inspect -f '{{.State.Status}}' "$BACKEND_CONTAINER" 2>/dev/null)" = "running" ] && \
      docker exec "$BACKEND_CONTAINER" bash -c 'cat < /dev/null > /dev/tcp/localhost/3000' 2>/dev/null || [ $RETRY -ge $MAX_RETRIES ]; do
    echo "  En attente... ($RETRY/$MAX_RETRIES)"
    sleep 5
    RETRY=$((RETRY + 1))
done

if [ $RETRY -ge $MAX_RETRIES ]; then
    echo "  ATTENTION: health check timeout — bascule annulee"
    echo "  La couleur $CURRENT_COLOR reste active"
    exit 1
fi

echo "  $NEW_COLOR est operationnel"
echo ""

# ── Etape 5 : Basculer le reverse proxy ─────────────────────────
echo "[5/5] Bascule du reverse proxy vers $NEW_COLOR..."

cat > "$ACTIVE_CONF" << EOF
# Couleur active : $NEW_COLOR
# Mis a jour automatiquement par scripts/deploy-blue-green.sh
# Date : $(date -u +"%Y-%m-%dT%H:%M:%SZ")

upstream active_backend {
    server backend-${NEW_COLOR}:3000;
}

upstream active_frontend {
    server frontend-${NEW_COLOR}:80;
}
EOF

docker exec gym_proxy nginx -s reload
echo "  Proxy bascule vers $NEW_COLOR"
echo ""

# ── Resume ───────────────────────────────────────────────────────
echo "================================================"
echo "  Deploiement termine avec succes !"
echo "================================================"
echo ""
echo "  Couleur active    : $NEW_COLOR"
echo "  Couleur standby   : $CURRENT_COLOR (rollback disponible)"
echo "  Application       : http://localhost"
echo ""
echo "  Pour rollback vers $CURRENT_COLOR :"
echo "  ROLLBACK_COLOR=$CURRENT_COLOR ./scripts/rollback-blue-green.sh"
echo ""
