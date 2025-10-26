#!/usr/bin/env bash
# ============================================================
#  XMRig Autotune Utility
#  Purpose: Benchmark optimal thread configuration for XMRig
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

LOG_DIR="/var/log/miner-lab"
LOG_FILE="$LOG_DIR/xmrig-autotune.log"
CONFIG_FILE="/opt/miner-lab/xmrig.json"
ENV_FILE="/etc/miner-lab/.env"
XMRIG_BIN="${XMRIG_PATH:-/usr/local/bin/xmrig}"

mkdir -p "$LOG_DIR"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
else
  warn "Environment file not found at $ENV_FILE; using defaults."
fi

# Confirm xmrig binary
if ! command -v "$XMRIG_BIN" >/dev/null 2>&1; then
  error "XMRig binary not found at $XMRIG_BIN"
  exit 1
fi

log "Starting XMRig autotune benchmark..."
{
  echo "------------------------------------------------------------"
  echo "XMRig Autotune started at: $(date)"
  echo "Host: $(hostname)"
  echo "Binary: $XMRIG_BIN"
  echo "------------------------------------------------------------"
} >> "$LOG_FILE"

# Run benchmark
if "$XMRIG_BIN" --version >/dev/null 2>&1; then
  "$XMRIG_BIN" --bench --threads=auto --time-limit=60 >>"$LOG_FILE" 2>&1 || warn "Benchmark completed with warnings."
else
  error "XMRig binary could not execute."
  exit 1
fi

# Optionally extract and apply tuned config
if grep -q "tune=" "$LOG_FILE"; then
  TUNE_LINE=$(grep "tune=" "$LOG_FILE" | tail -n1 | sed 's/.*tune=//')
  echo "{\"cpu\":{\"tune\":$TUNE_LINE}}" > "$CONFIG_FILE"
  log "Generated tuned config: $CONFIG_FILE"
else
  warn "No tune data detected; config unchanged."
fi

log "Autotune process complete. Logs saved at $LOG_FILE"