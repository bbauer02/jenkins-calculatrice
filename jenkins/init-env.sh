#!/usr/bin/env bash
# Crée le fichier jenkins/.env utilisé par compose.yaml.
# Usage : ./init-env.sh   (depuis le dossier jenkins/)
set -euo pipefail
cd "$(dirname "$0")"
export MSYS_NO_PATHCONV=1   # Git Bash (Windows) : ne pas convertir les chemins /var/...

if [ -f .env ]; then
  read -r -p "Le fichier .env existe déjà. L'écraser ? [o/N] " rep
  [[ "$rep" =~ ^[oO]$ ]] || { echo "Rien n'a été modifié."; exit 0; }
fi

if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker ne répond pas. Démarrez Docker (Docker Desktop, ou 'sudo systemctl start docker')."
  exit 1
fi

# GID du socket Docker tel qu'il est vu depuis un conteneur
# (identique sur Linux et Docker Desktop, contrairement à 'stat' lancé sur l'hôte)
DOCKER_GID=$(docker run --rm -v /var/run/docker.sock:/var/run/docker.sock alpine stat -c %g /var/run/docker.sock)

# Les variables peuvent être fournies à l'avance (utile pour automatiser)
JENKINS_ADMIN_ID=${JENKINS_ADMIN_ID:-}
JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD:-}
JENKINS_URL=${JENKINS_URL:-}

if [ -z "$JENKINS_ADMIN_ID" ]; then
  read -r -p "Identifiant de l'administrateur Jenkins [admin] : " JENKINS_ADMIN_ID
  JENKINS_ADMIN_ID=${JENKINS_ADMIN_ID:-admin}
fi

while [ ${#JENKINS_ADMIN_PASSWORD} -lt 8 ] || [[ "$JENKINS_ADMIN_PASSWORD" == *"'"* ]]; do
  read -r -s -p "Mot de passe de l'administrateur (8 caractères minimum, sans apostrophe) : " JENKINS_ADMIN_PASSWORD
  echo
done

JENKINS_PORT=${JENKINS_PORT:-}
if [ -z "$JENKINS_PORT" ]; then
  read -r -p "Port de Jenkins sur cette machine [8080] : " JENKINS_PORT
  JENKINS_PORT=${JENKINS_PORT:-8080}
fi

if [ -z "$JENKINS_URL" ]; then
  read -r -p "URL de Jenkins [http://localhost:${JENKINS_PORT}/] : " JENKINS_URL
  JENKINS_URL=${JENKINS_URL:-http://localhost:${JENKINS_PORT}/}
fi

cat > .env <<EOF
# Généré par init-env.sh — ne pas versionner (contient un mot de passe)
JENKINS_ADMIN_ID=${JENKINS_ADMIN_ID}
JENKINS_ADMIN_PASSWORD='${JENKINS_ADMIN_PASSWORD}'
JENKINS_URL=${JENKINS_URL}
JENKINS_PORT=${JENKINS_PORT}
DOCKER_GID=${DOCKER_GID}
EOF
chmod 600 .env

echo "✅ Fichier .env créé (groupe du socket Docker : ${DOCKER_GID})."
echo "   Lancez maintenant : docker compose up -d --build"
