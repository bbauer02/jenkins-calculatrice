#!/bin/bash
# Construit l'image (tests compris) et (re)lance l'application sur le port 3000
set -e

echo "********************************"
echo "CONSTRUCTION DE L'APPLICATION SUR LE PORT 3000"
docker compose up -d --build
echo "********************************"
date
