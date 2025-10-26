#!/usr/bin/env bash
# ============================================================
#  Miner-Lab Bootstrap Installer
#  Target: Debian 13.x (Trixie) Minimal
#  Author: Miner-Lab Project
# ============================================================

set -euo pipefail
IFS=$'\n\t'

# ----------[ COLOR CODES ]----------
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
RESET="\033[0m"

# ----------[ LOGGING ]----------
log()   { echo -e "${GREEN}[+]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $*"; }
error() { echo -e "${RED}[-]${RESET} $*" >&2; }

# ----------[ ROOT CHECK ]----------
if [ "$EUID" -ne 0 ]; then
  error "Please run as root (sudo -i or su -)."
  exit 1
fi

# ----------[ SANITY CHECKS ]----------
log "Checking network connectivity..."
ping -q -c1 github.com >/dev/null 2>&1 || {
  error "No network connectivity. Check your internet and try again."
  exit 1
}

if ! grep -qi "debian" /etc/os-release; then
  warn "Non-Debian system detected. Proceeding anyway."
fi

# ----------[ CONFIGURATION ]----------
REPO_URL="https://github.com/<YOUR_GITHUB_USERNAME>/miner-lab.git"
INSTALL_DIR="/opt/miner-lab"
LOG_DIR="/var/log/miner-lab"
ENV_FILE="/etc/miner-lab/.env"
PY_ENV="$INSTALL_DIR/venv"
USER_NAME="minerlab"

# ----------[ INSTALL DEPENDENCIES ]----------
log "Installing dependencies..."
apt-get update -y
apt-get install -y --no-install-recommends \
  git curl python3 python3-pip python3-venv logrotate jq net-tools ca-certificates

# ----------[ CREATE USER & DIRECTORIES ]----------
log "Creating user and directories..."
id -u $USER_NAME >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin -d "$INSTALL_DIR" "$USER_NAME"
mkdir -p "$LOG_DIR" /etc/miner-lab

# ----------[ CLONE OR UPDATE REPO ]----------
if [ -d "$INSTALL_DIR/.git" ]; then
  log "Repository already exists, pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  log "Cloning repository to $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# ----------[ SET PERMISSIONS ]----------
chown -R "$USER_NAME":"$USER_NAME" "$INSTALL_DIR" "$LOG_DIR" /etc/miner-lab

# ----------[ PYTHON ENVIRONMENT ]----------
log "Setting up Python virtual environment..."
if [ ! -d "$PY_ENV" ]; then
  python3 -m venv "$PY_ENV"
fi
source "$PY_ENV/bin/activate"
pip install --upgrade pip
pip install -r "$INSTALL_DIR/docs/requirements.txt"
deactivate

# ----------[ COPY CONFIG FILES ]----------
log "Copying configuration files..."
cp -f "$INSTALL_DIR/config/logrotate.d-miner-lab" /etc/logrotate.d/miner-lab

if [ ! -f "$ENV_FILE" ]; then
  cp "$INSTALL_DIR/config/example.env" "$ENV_FILE"
  warn "Environment file created at $ENV_FILE. Edit values before first run if needed."
fi

# ----------[ INSTALL SYSTEMD SERVICES ]----------
log "Installing systemd service units..."
SYSTEMD_DIR="/etc/systemd/system"

install_service() {
  local svc_dir="$1"
  cp -f "$INSTALL_DIR/services/$svc_dir"/*.service "$SYSTEMD_DIR"/
  if compgen -G "$INSTALL_DIR/services/$svc_dir/*.timer" > /dev/null; then
    cp -f "$INSTALL_DIR/services/$svc_dir"/*.timer "$SYSTEMD_DIR"/
  fi
}

install_service "miner-syncd"
install_service "xmrig-summary"
install_service "xmrig-watchdog"

systemctl daemon-reload

# ----------[ ENABLE & START SERVICES ]----------
log "Enabling and starting services..."
systemctl enable --now miner-syncd.service || warn "miner-syncd failed to start."
systemctl enable --now xmrig-summary.timer || warn "xmrig-summary.timer failed to start."
systemctl enable --now xmrig-watchdog.timer || warn "xmrig-watchdog.timer failed to start."

# ----------[ FINAL STATUS ]----------
echo ""
log "Miner-Lab installation complete!"
echo -e "${CYAN}Log directory:${RESET} $LOG_DIR"
echo -e "${CYAN}Environment file:${RESET} $ENV_FILE"
echo ""
systemctl list-units --type=service | grep miner || true
echo ""
log "You can verify operation with:"
echo "  journalctl -u miner-syncd.service -f"
echo "  systemctl status xmrig-summary.timer"
echo ""
log "Bootstrap complete!"