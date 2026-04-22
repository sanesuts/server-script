#!/bin/bash

set -e

echo "🚀 Activation mode serveur stable (no sleep + Intel fix + systemd hard lock)..."

# =========================
# 1. BACKUP GRUB
# =========================
echo "⚙️ Configuration GRUB Intel UHD fix..."

GRUB_FILE="/etc/default/grub"
sudo cp $GRUB_FILE ${GRUB_FILE}.bak

# Fix Intel GPU + KVM stability
sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet i915.enable_psr=0 i915.enable_dc=0 i915.enable_fbc=0"/' $GRUB_FILE

# =========================
# 2. SYSTEMD SLEEP TARGETS (IMPORTANT)
# =========================
echo "🚫 Mask des targets sleep systemd..."

sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

sudo systemctl mask sleep.target 2>/dev/null || true
sudo systemctl mask suspend.target 2>/dev/null || true
sudo systemctl mask hibernate.target 2>/dev/null || true
sudo systemctl mask hybrid-sleep.target 2>/dev/null || true

# =========================
# 3. LOGIND HARD CONFIG
# =========================
echo "⚙️ Configuration systemd-logind..."

sudo cp /etc/systemd/logind.conf /etc/systemd/logind.conf.bak 2>/dev/null || true

cat <<EOF | sudo tee /etc/systemd/logind.conf
[Login]
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
IdleActionSec=0
EOF

sudo systemctl restart systemd-logind

# =========================
# 4. GNOME POWER (si présent)
# =========================
echo "🖥️ Désactivation GNOME power..."

if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing' 2>/dev/null || true
    gsettings set org.gnome.desktop.session idle-delay 0 2>/dev/null || true
    gsettings set org.gnome.desktop.screensaver lock-enabled false 2>/dev/null || true
    gsettings set org.gnome.desktop.screensaver idle-activation-enabled false 2>/dev/null || true
fi

# =========================
# 5. X11 DPMS (si actif)
# =========================
echo "📺 Désactivation DPMS..."

if command -v xset &> /dev/null; then
    xset s off 2>/dev/null || true
    xset -dpms 2>/dev/null || true
fi

# =========================
# 6. UPDATE GRUB
# =========================
echo "🔄 update-grub..."

sudo update-grub

# =========================
# DONE
# =========================
echo "✅ MODE SERVEUR ACTIF"
echo "💡 Reboot obligatoire : sudo reboot"
