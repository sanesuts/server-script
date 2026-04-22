#!/bin/bash

set -e

echo "🚀 Installation de Portainer Agent..."

# =========================
# 1. Lancer Portainer Agent
# =========================

docker run -d \
  --name portainer_agent \
  --restart=always \
  -p 9001:9001 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  portainer/agent:latest

echo "✅ Portainer Agent installé et lancé"
echo "👉 Port ouvert : 9001"
