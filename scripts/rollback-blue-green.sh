#!/bin/bash
set -e

# ================================================
#   Gym Management System - Blue/Green Rollback
# ================================================
# Rebascule instantanement vers l'ancienne couleur
# sans redemarrer aucun conteneur applicatif

WORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ACTIVE_CONF="$WORK_DIR/nginx/conf.d/active.conf"

echo "================================================"
echo "  Blue/Green Rollback"
echo "================================================"
echo ""

# Detecter la couleur active actuelle
if docker ps --format "{{.Names}}" | grep -q "gym_backend_blue"; then
    CURRENT_COLOR="blue"
    ROLLBACK_COLOR="${ROLLBACK_COLOR:-green}"
else
    CURRENT_COLOR="green"
    ROLLBACK_COLOR="${ROLLBACK_COLOR:-blue}"
fi

# Verifier que la couleur de rollback tourne bien
if ! docker ps --format "{{.Names}}" | grep -q "gym_backend_$ROLLBACK_COLOR"; then
    echo "ERREUR : gym_backend_$ROLLBACK_COLOR n'est pas en cours d'execution"
    echo "Impossible de faire un rollback vers $ROLLBACK_COLOR"
    exit 1
fi

echo "  Couleur active    : $CURRENT_COLOR"
echo "  Rollback vers     : $ROLLBACK_COLOR"
echo ""

cat > "$ACTIVE_CONF" << EOF
# Couleur active : $ROLLBACK_COLOR
# Rollback effectue le $(date -u +"%Y-%m-%dT%H:%M:%SZ")

upstream active_backend {
    server backend-${ROLLBACK_COLOR}:3000;
}

upstream active_frontend {
    server frontend-${ROLLBACK_COLOR}:80;
}
EOF

docker exec gym_proxy nginx -s reload

echo "================================================"
echo "  Rollback effectue !"
echo "================================================"
echo ""
echo "  Couleur active : $ROLLBACK_COLOR"
echo "  Application    : http://localhost"
echo ""
