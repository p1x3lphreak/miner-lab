#!/usr/bin/env bash
# ============================================================
#  Miner-Lab Component Installer: xmrig-watchdog
# ============================================================

set -euo pipefail
IFS=$'\n\t'

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"
log()   { echo -e "${GREEN}[+]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $*"; }
error() { echo -e "${RED}[-]${RESET} $*" >&2; }

# Root check
if [ "$EUID" -ne 0 ]; then
  error "Please run as root or with sudo."
  exit 1
fi

INSTALL_DIR="/opt/miner-lab"
SYSTEMD_DIR="/etc/systemd/system"
SERVICE_SRC="$INSTALL_DIR/services/xmrig-watchdog/xmrig-watchdog.service"
TIMER_SRC="$INSTALL_DIR/services/xmrig-watchdog/xmrig-watchdog.timer"
ENV_FILE="/etc/miner-lab/.env"
LOG_DIR="/var/log/miner-lab"
USER_NAME="minerlab"
VENV_DIR="$INSTALL_DIR/venv"

log "Installing xmrig-watchdog service and timer..."

# Create directories and user if needed
id -u "$USER_NAME" >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin -d "$INSTALL_DIR" "$USER_NAME"
mkdir -p "$LOG_DIR" /etc/miner-lab
chown -R "$USER_NAME":"$USER_NAME" "$INSTALL_DIR" "$LOG_DIR" /etc/miner-lab

# Python environment
if [ ! -d "$VENV_DIR" ]; then
  log "Creating Python virtual environment..."
  python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r "$INSTALL_DIR/docs/requirements.txt"
deactivate

# Copy service and timer files
cp -f "$SERVICE_SRC" "$SYSTEMD_DIR/"
cp -f "$TIMER_SRC" "$SYSTEMD_DIR/"
systemctl daemon-reload

# Ensure environment file exists
if [ ! -f "$ENV_FILE" ]; then
  cp "$INSTALL_DIR/config/example.env" "$ENV_FILE"
  warn "Environment file created at $ENV_FILE. Review it before enabling the service."
fi

# Enable & start
systemctl enable --now xmrig-watchdog.timer

log "xmrig-watchdog installed and timer activated."
systemctl list-timers --all | grep xmrig-watchdog || true