#!/bin/bash

# ============================================

# Script : install-docker.sh

# Objectif : Installer Docker + Docker Compose (plugin officiel)

# Compatible : Debian (Bullseye / Bookworm)

# ============================================

set -e

echo "🚀 Installation de Docker en cours..."

# 1. Mise à jour

apt update && apt upgrade -y

# 2. Dépendances nécessaires

apt install -y ca-certificates curl gnupg

# 3. Ajouter la clé officielle Docker

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# 4. Ajouter le repo Docker

echo 
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian 
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \

> /etc/apt/sources.list.d/docker.list

# 5. Installation Docker

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 6. Activer Docker au démarrage

systemctl enable docker
systemctl start docker

# 7. Ajouter l'utilisateur actuel au groupe docker

if [ -n "$SUDO_USER" ]; then
usermod -aG docker $SUDO_USER
echo "👤 Ajout de $SUDO_USER au groupe docker"
fi

# 8. Vérification

echo "🔍 Vérification de Docker..."
docker --version
docker compose version

echo "✅ Docker et Docker Compose installés avec succès !"
echo "⚠️ IMPORTANT : Déconnecte-toi et reconnecte-toi pour utiliser Docker sans sudo."
