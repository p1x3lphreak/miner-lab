#!/usr/bin/env bash
# ============================================================
#  Miner-Lab Component Installer: xmrig-autotune
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

if [ "$EUID" -ne 0 ]; then
  error "Please run as root or with sudo."
  exit 1
fi

INSTALL_DIR="/opt/miner-lab"
SCRIPT_SRC="$INSTALL_DIR/scripts/xmrig-autotune.sh"
BIN_LINK="/usr/local/bin/xmrig-autotune"
LOG_DIR="/var/log/miner-lab"
ENV_FILE="/etc/miner-lab/.env"
USER_NAME="minerlab"

log "Installing XMRig autotune utility..."

# Ensure environment and log directories
mkdir -p "$LOG_DIR" /etc/miner-lab
chown -R "$USER_NAME":"$USER_NAME" "$INSTALL_DIR" "$LOG_DIR" /etc/miner-lab

# Ensure environment file exists
if [ ! -f "$ENV_FILE" ]; then
  cp "$INSTALL_DIR/config/example.env" "$ENV_FILE"
  warn "Environment file created at $ENV_FILE. Update before running autotune."
fi

# Make script executable and symlink globally
chmod +x "$SCRIPT_SRC"
ln -sf "$SCRIPT_SRC" "$BIN_LINK"

log "Autotune utility installed globally as 'xmrig-autotune'."
log "Run it manually with: xmrig-autotune"