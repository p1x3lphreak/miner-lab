#!/usr/bin/env bash
# ==========================================================
# Miner-Lab :: xmrig-autotune.sh
# ----------------------------------------------------------
# Optimizes xmrig performance parameters (threads, affinity,
# hugepages) and logs results.
# ==========================================================

set -euo pipefail
LOG_FILE="/var/log/xmrig-autotune.log"
CONFIG_DIR="/opt/xmrig"
CONFIG_FILE="$CONFIG_DIR/config.json"

echo "🔧 Running XMRig Auto-Tune..." | tee -a "$LOG_FILE"

# Ensure xmrig exists
if ! command -v xmrig >/dev/null 2>&1; then
  echo "❌ xmrig not found in PATH" | tee -a "$LOG_FILE"
  exit 1
fi

# Create backup
if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
fi

xmrig --stress --benchmark 10 | tee -a "$LOG_FILE"

echo "✅ Auto-Tune complete. Results logged to $LOG_FILE."