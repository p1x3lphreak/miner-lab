#!/usr/bin/env bash
# ============================================================
# Miner-Lab Unified Installer
# Version: 1.1.0
# Author: Justin Farry (p1x3lphreak)
# ============================================================

set -euo pipefail
LOG_FILE="/var/log/miner-lab-install.log"
INSTALL_DIR="/opt/miner-lab"
ENV_FILE="/etc/miner-lab.env"
GITHUB_REPO="https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main"

WITH_AUTOTUNE=false
FORCE_RECONF=false

# --- Parse Flags ---
for arg in "$@"; do
  case $arg in
    --with-autotune) WITH_AUTOTUNE=true ;;
    --force) FORCE_RECONF=true ;;
    *) echo "Unknown option: $arg" && exit 1 ;;
  esac
done

echo "⚙️ Starting Miner-Lab installation..."
sudo mkdir -p "$(dirname "$LOG_FILE")"
sudo touch "$LOG_FILE"

# ------------------------------------------------------------
# 1️⃣ Core Dependencies
# ------------------------------------------------------------
echo "📦 Installing dependencies..." | tee -a "$LOG_FILE"
sudo apt-get update -y
sudo apt-get install -y python3 python3-venv python3-pip curl git jq logrotate systemd | tee -a "$LOG_FILE"

# ------------------------------------------------------------
# 2️⃣ Directory Layout
# ------------------------------------------------------------
echo "📁 Setting up directory structure..."
sudo mkdir -p "$INSTALL_DIR"/{scripts,services,install-scripts,logs}
sudo chown -R "$USER":"$USER" "$INSTALL_DIR"

# ------------------------------------------------------------
# 3️⃣ Environment Setup
# ------------------------------------------------------------
if $FORCE_RECONF; then
  echo "🔁 Force reconfig enabled — removing old env file..."
  sudo rm -f "$ENV_FILE"
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "🌍 Creating environment file..."
  read -rp "Enter RIG name (default: mine-lab): " RIG_NAME
  RIG_NAME=${RIG_NAME:-mine-lab}
  read -rp "Enter Pushcut Alert Webhook URL: " PUSHCUT_ALERT_URL
  read -rp "Enter Pushcut Summary Webhook URL: " PUSHCUT_SUMMARY_URL

  sudo bash -c "cat > $ENV_FILE" <<EOF
RIG_NAME="$RIG_NAME"
PUSHCUT_ALERT_URL="$PUSHCUT_ALERT_URL"
PUSHCUT_SUMMARY_URL="$PUSHCUT_SUMMARY_URL"
EOF
  echo "✅ Environment file created at $ENV_FILE"
else
  echo "⚙️ Environment file already exists — skipping setup."
fi

# ------------------------------------------------------------
# 4️⃣ Pull Sub-Installers
# ------------------------------------------------------------
echo "⬇️ Fetching installer scripts..."
curl -fsSL "$GITHUB_REPO/install-scripts/install-miner-syncd.sh" -o "$INSTALL_DIR/install-scripts/install-miner-syncd.sh"
curl -fsSL "$GITHUB_REPO/install-scripts/install-xmrig-summary.sh" -o "$INSTALL_DIR/install-scripts/install-xmrig-summary.sh"
curl -fsSL "$GITHUB_REPO/install-scripts/install-xmrig-watchdog.sh" -o "$INSTALL_DIR/install-scripts/install-xmrig-watchdog.sh"
curl -fsSL "$GITHUB_REPO/install-scripts/install-xmrig-autotune.sh" -o "$INSTALL_DIR/install-scripts/install-xmrig-autotune.sh"
chmod +x "$INSTALL_DIR"/install-scripts/*.sh

# ------------------------------------------------------------
# 5️⃣ Pull Service Units
# ------------------------------------------------------------
echo "⬇️ Fetching service & timer units..."
SERVICES_DIR="/etc/systemd/system"

curl -fsSL "$GITHUB_REPO/services/miner-syncd/miner-syncd.service" -o "$SERVICES_DIR/miner-syncd.service"
curl -fsSL "$GITHUB_REPO/services/xmrig-summary/xmrig-summary.service" -o "$SERVICES_DIR/xmrig-summary.service"
curl -fsSL "$GITHUB_REPO/services/xmrig-summary/xmrig-summary.timer" -o "$SERVICES_DIR/xmrig-summary.timer"
curl -fsSL "$GITHUB_REPO/services/xmrig-watchdog/xmrig-watchdog.service" -o "$SERVICES_DIR/xmrig-watchdog.service"
curl -fsSL "$GITHUB_REPO/services/xmrig-watchdog/xmrig-watchdog.timer" -o "$SERVICES_DIR/xmrig-watchdog.timer"

sudo chmod 644 "$SERVICES_DIR"/*.service "$SERVICES_DIR"/*.timer

# ------------------------------------------------------------
# 6️⃣ Deploy Scripts
# ------------------------------------------------------------
echo "📜 Deploying core daemon scripts..."
curl -fsSL "$GITHUB_REPO/scripts/miner-syncd.py" -o "$INSTALL_DIR/scripts/miner-syncd.py"
sudo chmod +x "$INSTALL_DIR/scripts/"*.py

# ------------------------------------------------------------
# 7️⃣ Logrotate Configuration
# ------------------------------------------------------------
echo "🌀 Installing logrotate config..."
sudo curl -fsSL "$GITHUB_REPO/logrotate/miner-lab" -o /etc/logrotate.d/miner-lab
sudo chmod 644 /etc/logrotate.d/miner-lab
echo "✅ Log rotation set for xmrig-watchdog.log and miner-syncd.log"

# ------------------------------------------------------------
# 8️⃣ Enable and Start Services
# ------------------------------------------------------------
echo "🚀 Enabling services..."
sudo systemctl daemon-reload
sudo systemctl enable miner-syncd.service
sudo systemctl enable xmrig-summary.timer
sudo systemctl enable xmrig-watchdog.timer

sudo systemctl start miner-syncd.service
sudo systemctl start xmrig-summary.timer
sudo systemctl start xmrig-watchdog.timer

# ------------------------------------------------------------
# 9️⃣ Optional Autotune
# ------------------------------------------------------------
if $WITH_AUTOTUNE; then
  echo "🎛️ Running XMRig Autotune..."
  if [ -f "$INSTALL_DIR/install-scripts/xmrig-autotune.sh" ]; then
    bash "$INSTALL_DIR/install-scripts/xmrig-autotune.sh" | tee -a "$LOG_FILE"
  else
    echo "⚠️ Autotune script missing — skipping autotune." | tee -a "$LOG_FILE"
  fi
else
  echo "ℹ️ Autotune not requested. Skipping."
fi

# ------------------------------------------------------------
# 🔟 Verification
# ------------------------------------------------------------
echo "🔍 Verifying systemd timers and services..."
systemctl list-timers --all | grep xmrig || echo "ℹ️ Timers not yet active — will start soon."
sudo systemctl status miner-syncd --no-pager | grep Active

# ------------------------------------------------------------
# 🏁 Wrap-up
# ------------------------------------------------------------
echo "🎉 Miner-Lab installation complete!"
echo "  🧩 Config: $ENV_FILE"
echo "  📂 Installed to: $INSTALL_DIR"
echo "  🧠 Daemon: miner-syncd.service (active)"
echo "  🕒 Timers: xmrig-summary.timer, xmrig-watchdog.timer"
$WITH_AUTOTUNE && echo "  ⚙️ Autotune: xmrig-autotune.sh executed successfully"
echo "  📋 Logs: $LOG_FILE"