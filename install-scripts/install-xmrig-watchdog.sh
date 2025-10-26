#!/usr/bin/env bash
# ==========================================================
# Miner-Lab :: install-xmrig-watchdog.sh
# ----------------------------------------------------------
# Installs and configures the xmrig-watchdog service + timer.
# Monitors xmrig process health and restarts if stalled.
# ==========================================================

set -euo pipefail
REPO_BASE="https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main"
SERVICE_DIR="/etc/systemd/system"
APP_DIR="/opt/xmrig-watchdog"
ENV_FILE="/etc/miner-syncd.env"

echo "🐶 Installing XMRig Watchdog Service..."

# --- 1. Dependencies --------------------------------------------------------
sudo apt update -y
sudo apt install -y python3 python3-venv python3-pip curl psmisc

# --- 2. Application Directory ----------------------------------------------
sudo mkdir -p "$APP_DIR"
sudo curl -fsSL "$REPO_BASE/scripts/xmrig-watchdog.py" -o "$APP_DIR/xmrig-watchdog.py"
sudo python3 -m venv "$APP_DIR/venv"
sudo "$APP_DIR/venv/bin/pip" install --upgrade pip psutil requests

# --- 3. Environment Check ---------------------------------------------------
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Environment file not found at $ENV_FILE"
  echo "Run install-miner-syncd.sh first!"
  exit 1
fi

# --- 4. Deploy systemd units -----------------------------------------------
echo "⚙️ Deploying systemd service and timer..."
sudo curl -fsSL "$REPO_BASE/services/xmrig-watchdog/xmrig-watchdog.service" \
  -o "$SERVICE_DIR/xmrig-watchdog.service"
sudo curl -fsSL "$REPO_BASE/services/xmrig-watchdog/xmrig-watchdog.timer" \
  -o "$SERVICE_DIR/xmrig-watchdog.timer"

sudo chown root:root "$SERVICE_DIR"/xmrig-watchdog.*
sudo chmod 644 "$SERVICE_DIR"/xmrig-watchdog.*

sudo systemctl daemon-reload
sudo systemctl enable --now xmrig-watchdog.timer

# --- 5. Permissions ---------------------------------------------------------
sudo chown -R root:root "$APP_DIR"
sudo chmod +x "$APP_DIR/xmrig-watchdog.py"

# --- 6. Confirmation --------------------------------------------------------
echo "✅ XMRig Watchdog active and monitoring!"
systemctl list-timers --all | grep xmrig-watchdog || true