#!/usr/bin/env bash
# ==========================================================
# Miner-Lab :: install-miner-syncd.sh
# ----------------------------------------------------------
# Installs and configures the miner-syncd daemon.
# Pulls service units directly from the GitHub repo.
# ==========================================================

set -euo pipefail
REPO_BASE="https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main"
SERVICE_DIR="/etc/systemd/system"
APP_DIR="/opt/miner-syncd"
ENV_FILE="/etc/miner-syncd.env"
CONFIG_FILE="/etc/miner-syncd/config.json"

echo "🚀 Installing Miner Sync Daemon..."

# --- 1. Dependencies --------------------------------------------------------
sudo apt update -y
sudo apt install -y python3 python3-venv python3-pip curl

# --- 2. Application Directory ----------------------------------------------
echo "📂 Setting up app directory at $APP_DIR"
sudo mkdir -p "$APP_DIR"
sudo curl -fsSL "$REPO_BASE/scripts/miner-syncd.py" -o "$APP_DIR/miner-syncd.py"
sudo python3 -m venv "$APP_DIR/venv"
sudo "$APP_DIR/venv/bin/pip" install --upgrade pip requests

# --- 3. Environment File ----------------------------------------------------
if [[ "${1:-}" == "--force" ]]; then
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

sudo chown root:root "$ENV_FILE"
sudo chmod 600 "$ENV_FILE"

# --- 4. Config File ---------------------------------------------------------
if [ ! -f "$CONFIG_FILE" ]; then
  echo "🧩 Generating default config.json..."
  sudo mkdir -p "$(dirname "$CONFIG_FILE")"
  sudo bash -c "cat > $CONFIG_FILE" <<EOF
{
  "rig": "$RIG_NAME",
  "miners": [],
  "last_sync": null
}
EOF
  sudo chown root:root "$CONFIG_FILE"
  sudo chmod 644 "$CONFIG_FILE"
else
  echo "🧠 Existing config.json found — leaving untouched."
fi
# --- logrotate copy
sudo cp ./config/logrotate-d-miner-lab /etc/logrotate.d/miner-lab
sudo chmod 644 /etc/logrotate.d/miner-lab
sudo logrotate --debug /etc/logrotate.d/miner-lab

# --- 5. Systemd Service Deployment -----------------------------------------
echo "⚙️ Deploying systemd service..."
sudo curl -fsSL "$REPO_BASE/services/miner-syncd/miner-syncd.service" \
  -o "$SERVICE_DIR/miner-syncd.service"

sudo chown root:root "$SERVICE_DIR/miner-syncd.service"
sudo chmod 644 "$SERVICE_DIR/miner-syncd.service"

sudo systemctl daemon-reload
sudo systemctl enable --now miner-syncd

# --- 6. Permissions ---------------------------------------------------------
sudo chown -R root:root "$APP_DIR"
sudo chmod +x "$APP_DIR/miner-syncd.py"

# --- 7. Confirmation --------------------------------------------------------
echo "✅ Miner Sync Daemon successfully installed!"
systemctl status miner-syncd --no-pager | head -n 12