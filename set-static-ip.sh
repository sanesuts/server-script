#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# USAGE
# -----------------------------
usage() {
  echo "Usage:"
  echo "  sudo $0 -i <ip/cidr> -d <dns1,dns2> [-c <new-conn-name>]"
  echo ""
  echo "Exemple:"
  echo "  sudo $0 -i 192.168.1.156/24 -d 1.1.1.1,8.8.8.8 -c static-eth"
  exit 1
}

# -----------------------------
# ARGS
# -----------------------------
while getopts "i:d:c:" opt; do
  case "$opt" in
    i) IP="$OPTARG" ;;
    d) DNS="$OPTARG" ;;
    c) NEWCONN="$OPTARG" ;;
    *) usage ;;
  esac
done

[[ -z "${IP:-}" || -z "${DNS:-}" ]] && usage

NEWCONN="${NEWCONN:-static-conn-$(date +%s)}"

# -----------------------------
# AUTO DETECTION INTERFACE
# -----------------------------
IFACE=$(nmcli -t -f DEVICE,STATE device | grep connected | head -n1 | cut -d: -f1)

if [[ -z "$IFACE" ]]; then
  echo "❌ Impossible de détecter l'interface active"
  exit 1
fi

# -----------------------------
# AUTO DETECTION GATEWAY
# -----------------------------
GW=$(ip route | grep default | awk '{print $3}' | head -n1)

if [[ -z "$GW" ]]; then
  echo "❌ Impossible de détecter la gateway"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📡 Interface détectée : $IFACE"
echo "🚪 Gateway détectée   : $GW"
echo "🌐 IP cible           : $IP"
echo "🔎 DNS                : $DNS"
echo "🧷 Nouvelle connexion : $NEWCONN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# -----------------------------
# CRÉATION NOUVELLE CONNEXION
# -----------------------------
echo "🧷 Création nouvelle connexion..."

sudo nmcli connection add \
  type ethernet \
  ifname "$IFACE" \
  con-name "$NEWCONN" \
  ipv4.method manual \
  ipv4.addresses "$IP" \
  ipv4.gateway "$GW" \
  ipv4.dns "$(echo $DNS | tr ',' ' ')" \
  autoconnect yes

# -----------------------------
# SAFE APPLY (ROLLBACK SYSTEM)
# -----------------------------
echo "🚨 Activation avec rollback sécurité..."

OLD_CONN=$(nmcli -t -f NAME,DEVICE connection show --active | grep "$IFACE" | cut -d: -f1 || true)

sudo nmcli connection up "$NEWCONN"

# -----------------------------
# TEST CONNECTIVITÉ
# -----------------------------
echo "🧪 Test connectivité (ping gateway)..."

sleep 3

if ping -c 3 "$GW" >/dev/null 2>&1; then
    echo "✅ Réseau OK, validation config"

    # désactiver ancienne connexion si elle existe
    if [[ -n "$OLD_CONN" ]]; then
        echo "🧹 Désactivation ancienne connexion : $OLD_CONN"
        sudo nmcli connection down "$OLD_CONN" || true
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 CONFIG APPLIQUÉE AVEC SUCCÈS"
    echo "📡 Interface : $IFACE"
    echo "🧷 Connexion : $NEWCONN"
    ip -4 addr show "$IFACE" | grep inet
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

else
    echo "❌ PERTE DE CONNECTIVITÉ → ROLLBACK"

    sudo nmcli connection down "$NEWCONN" || true

    if [[ -n "$OLD_CONN" ]]; then
        echo "🔁 Restauration ancienne connexion : $OLD_CONN"
        sudo nmcli connection up "$OLD_CONN" || true
    fi

    echo "⚠️ Rollback terminé"
    exit 1
fi
