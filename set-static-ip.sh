#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Usage
# -----------------------------
usage() {
  echo "Usage:"
  echo "  sudo $0 -c <connection> -i <ip/cidr> -g <gateway> -d <dns1,dns2>"
  echo ""
  echo "Exemple:"
  echo "  sudo $0 -c 'Wired connection 1' -i 192.168.1.156/24 -g 192.168.1.1 -d 1.1.1.1,8.8.8.8"
  exit 1
}

# -----------------------------
# Args
# -----------------------------
while getopts "c:i:g:d:" opt; do
  case "$opt" in
    c) CONN="$OPTARG" ;;
    i) IP="$OPTARG" ;;
    g) GW="$OPTARG" ;;
    d) DNS="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "${CONN:-}" || -z "${IP:-}" || -z "${GW:-}" || -z "${DNS:-}" ]]; then
  usage
fi

echo "🔧 Configuration IP fixe via NetworkManager"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Connexion : $CONN"
echo "IP        : $IP"
echo "Gateway   : $GW"
echo "DNS       : $DNS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# -----------------------------
# Vérif connexion
# -----------------------------
nmcli connection show | grep -q "$CONN" || {
  echo "❌ Connexion introuvable : $CONN"
  exit 1
}

# -----------------------------
# Passage en manuel (IMPORTANT)
# -----------------------------
echo "⚙️ Passage en mode IP statique..."
sudo nmcli connection modify "$CONN" ipv4.method manual

# -----------------------------
# Nettoyage ancien DHCP
# -----------------------------
echo "🧹 Nettoyage ancienne config DHCP..."
sudo nmcli connection modify "$CONN" ipv4.addresses ""
sudo nmcli connection modify "$CONN" ipv4.gateway ""
sudo nmcli connection modify "$CONN" ipv4.dns ""

# -----------------------------
# Application config
# -----------------------------
echo "🌐 Application IP..."
sudo nmcli connection modify "$CONN" ipv4.addresses "$IP"

echo "🚪 Application gateway..."
sudo nmcli connection modify "$CONN" ipv4.gateway "$GW"

DNS_FMT=$(echo "$DNS" | tr ',' ' ')
echo "🔎 Application DNS..."
sudo nmcli connection modify "$CONN" ipv4.dns "$DNS_FMT"

# -----------------------------
# Restart connexion
# -----------------------------
echo "🔄 Redémarrage connexion..."
sudo nmcli connection down "$CONN" || true
sudo nmcli connection up "$CONN"

# -----------------------------
# Vérification
# -----------------------------
DEVICE=$(nmcli -t -f NAME,DEVICE connection show | grep "^$CONN:" | cut -d: -f2)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ CONFIG TERMINÉE"
echo "📡 Interface : $DEVICE"

echo "📊 IP actuelle :"
ip -4 addr show "$DEVICE" | grep inet || true

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
