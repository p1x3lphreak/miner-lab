#!/usr/bin/env bash
# ==========================================================
# Miner-Lab :: install-xmrig-summary.sh
# ----------------------------------------------------------
# Installs and configures the xmrig-summary daemon + timer.
# Pulls service units directly from GitHub repo.
# ==========================================================

set -euo pipefail
REPO_BASE="https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main"
SERVICE_DIR="/etc/systemd/system"
APP_DIR="/opt/xmrig-summary"
ENV_FILE="/etc/miner-syncd.env"

echo "📦 Installing XMRig Summary Daemon..."

# --- 1. Dependencies --------------------------------------------------------
sudo apt update -y
sudo apt install -y python3 python3-venv python3-pip curl

# --- 2. Application Directory ----------------------------------------------
sudo mkdir -p "$APP_DIR"
sudo curl -fsSL "$REPO_BASE/scripts/xmrig-summary.py" -o "$APP_DIR/xmrig-summary.py"
sudo python3 -m venv "$APP_DIR/venv"
sudo "$APP_DIR/venv/bin/pip" install --upgrade pip requests

# --- 3. Environment File Check ---------------------------------------------
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Environment file not found at $ENV_FILE"
  echo "Run install-miner-syncd.sh first!"
  exit 1
fi

# --- 4. Systemd Service + Timer Deployment ---------------------------------
echo "⚙️ Deploying systemd service and timer..."
sudo curl -fsSL "$REPO_BASE/services/xmrig-summary/xmrig-summary.service" \
  -o "$SERVICE_DIR/xmrig-summary.service"
sudo curl -fsSL "$REPO_BASE/services/xmrig-summary/xmrig-summary.timer" \
  -o "$SERVICE_DIR/xmrig-summary.timer"

sudo chown root:root "$SERVICE_DIR"/xmrig-summary.*
sudo chmod 644 "$SERVICE_DIR"/xmrig-summary.*

sudo systemctl daemon-reload
sudo systemctl enable --now xmrig-summary.timer

# --- 5. Permissions ---------------------------------------------------------
sudo chown -R root:root "$APP_DIR"
sudo chmod +x "$APP_DIR/xmrig-summary.py"

# --- 6. Confirmation --------------------------------------------------------
echo "✅ XMRig Summary installed and scheduled!"
systemctl list-timers --all | grep xmrig-summary || true