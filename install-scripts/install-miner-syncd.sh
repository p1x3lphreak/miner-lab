#!/usr/bin/env bash
# ==========================================================
# Miner-Lab :: install-miner-syncd.sh
# ----------------------------------------------------------
# Installs and configures the miner-syncd daemon
# in the unified /opt/miner-lab/ repo structure.
# ==========================================================

set -euo pipefail
REPO_BASE="https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main"
APP_DIR="/opt/miner-lab"
SCRIPT_PATH="$APP_DIR/scripts"
SERVICE_PATH="$APP_DIR/services/miner-syncd.service"
ENV_FILE="$APP_DIR/.env"
CONFIG_FILE="$APP_DIR/config/miner-syncd.json"
LOG_DIR="$APP_DIR/logs"

echo "🚀 Installing Miner Sync Daemon..."

# --- 1. Dependencies ---
sudo apt update -y
sudo apt install -y python3 python3-venv python3-pip curl jq

# --- 2. Directories ---
sudo mkdir -p "$SCRIPT_PATH" "$LOG_DIR" "$APP_DIR/config/logrotate"
sudo curl -fsSL "$REPO_BASE/scripts/miner-syncd.py" -o "$SCRIPT_PATH/miner-syncd.py"

# --- 3. Virtual Environment ---
if [ ! -d "$APP_DIR/venv" ]; then
  echo "🐍 Creating Python venv..."
  sudo python3 -m venv "$APP_DIR/venv"
fi
sudo "$APP_DIR/venv/bin/pip" install --upgrade pip requests psutil

# --- 4. Environment File ---
if [[ "${1:-}" == "--force" ]]; then
  echo "🔁 Force reconfig enabled — removing old env file..."
  sudo rm -f "$ENV_FILE"
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "🌍 Creating .env file..."
  read -rp "Enter RIG name (default: miner-lab): " RIG_NAME
  RIG_NAME=${RIG_NAME:-miner-lab}
  read -rp "Enter Pushcut Alert Webhook URL: " PUSHCUT_URL_ALERT
  read -rp "Enter Pushcut Summary Webhook URL: " PUSHCUT_URL_SUMMARY

  sudo bash -c "cat > $ENV_FILE" <<EOF
RIG_NAME="$RIG_NAME"
PUSHCUT_URL_ALERT="$PUSHCUT_URL_ALERT"
PUSHCUT_URL_SUMMARY="$PUSHCUT_URL_SUMMARY"
EOF
fi

sudo chown root:root "$ENV_FILE"
sudo chmod 600 "$ENV_FILE"

# --- 5. Default Config ---
if [ ! -f "$CONFIG_FILE" ]; then
  echo "🧩 Generating miner-syncd.json..."
  sudo bash -c "cat > $CONFIG_FILE" <<EOF
{
  "rig": "$RIG_NAME",
  "miners": [],
  "last_sync": null
}
EOF
fi
sudo chmod 644 "$CONFIG_FILE"

# --- 6. Logrotate ---
sudo curl -fsSL "$REPO_BASE/config/logrotate/miner-lab.conf" -o "/etc/logrotate.d/miner-lab"
sudo chmod 644 /etc/logrotate.d/miner-lab
sudo logrotate --debug /etc/logrotate.d/miner-lab || true

# --- 7. Systemd Service ---
echo "⚙️ Deploying systemd service..."
sudo curl -fsSL "$REPO_BASE/services/miner-syncd.service" -o "/etc/systemd/system/miner-syncd.service"
sudo chmod 644 /etc/systemd/system/miner-syncd.service
sudo systemctl daemon-reload
sudo systemctl enable --now miner-syncd

# --- 8. Ownership & Permissions ---
sudo chown -R root:root "$APP_DIR"
sudo chmod +x "$SCRIPT_PATH/miner-syncd.py"

echo "✅ Miner Sync Daemon successfully installed!"
systemctl status miner-syncd --no-pager | head -n 12