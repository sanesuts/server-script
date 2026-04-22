#!/bin/bash

#!/bin/bash

# ============================================

# Script : disable-sleep.sh

# Objectif : Désactiver toute mise en veille

# Compatible : Debian (serveur / mini PC)

# ============================================

set -e

echo "🔧 Désactivation de la mise en veille..."

# 1. Sauvegarde du fichier logind.conf

if [ -f /etc/systemd/logind.conf ]; then
cp /etc/systemd/logind.conf /etc/systemd/logind.conf.bak
echo "✅ Sauvegarde de logind.conf effectuée"
fi

# 2. Modification de logind.conf

echo "⚙️ Configuration de logind..."

sed -i 's/^#?HandleSuspendKey=.*/HandleSuspendKey=ignore/' /etc/systemd/logind.conf
sed -i 's/^#?HandleHibernateKey=.*/HandleHibernateKey=ignore/' /etc/systemd/logind.conf
sed -i 's/^#?HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
sed -i 's/^#?HandlePowerKey=.*/HandlePowerKey=ignore/' /etc/systemd/logind.conf
sed -i 's/^#?IdleAction=.*/IdleAction=ignore/' /etc/systemd/logind.conf

# 3. Bloquer complètement les targets de veille

echo "🚫 Blocage des modes veille (systemd)..."

systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 4. Redémarrage du service logind

echo "🔄 Redémarrage de systemd-logind..."

systemctl restart systemd-logind

# 5. Vérification

echo "🔍 Vérification des targets bloquées :"
systemctl status sleep.target | grep Loaded
systemctl status suspend.target | grep Loaded
systemctl status hibernate.target | grep Loaded

echo "✅ Mise en veille désactivée avec succès !"
echo "💡 Conseil : redémarre le serveur pour être sûr que tout est bien appliqué."
