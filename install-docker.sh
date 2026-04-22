#!/bin/bash

# ============================================
# Script : install-docker.sh
# Objectif : Installer Docker + Docker Compose (plugin officiel)
# Compatible : Debian (Bookworm recommandé)
# ============================================

set -e

echo "🚀 Installation de Docker en cours..."

# ----------------------------
# 1. Mise à jour système
# ----------------------------
apt update -y
apt upgrade -y

# ----------------------------
# 2. Dépendances nécessaires
# ----------------------------
apt install -y ca-certificates curl gnupg

# ----------------------------
# 3. Clé GPG officielle Docker
# ----------------------------
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

# ----------------------------
# 4. Repo Docker (FIX propre)
# ----------------------------

# ⚠️ Force Bookworm pour éviter les soucis avec testing (trixie)
CODENAME="bookworm"

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $CODENAME stable" \
> /etc/apt/sources.list.d/docker.list

# ----------------------------
# 5. Installation Docker
# ----------------------------
apt update -y

apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# ----------------------------
# 6. Activation Docker
# ----------------------------
systemctl enable docker
systemctl start docker

# ----------------------------
# 7. Ajouter utilisateur au groupe docker
# ----------------------------
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker "$SUDO_USER"
    echo "👤 Ajout de $SUDO_USER au groupe docker"
fi

# ----------------------------
# 8. Vérification
# ----------------------------
echo "🔍 Vérification de Docker..."

docker --version
docker compose version

echo ""
echo "✅ Docker et Docker Compose installés avec succès !"
echo "⚠️ Déconnecte-toi et reconnecte-toi pour utiliser Docker sans sudo."
