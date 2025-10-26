#!/usr/bin/env bash
# xmrig-autotune installer wrapper for Miner-Lab
# Fetches and installs the xmrig-autotune.sh utility into /opt/miner-lab/scripts

set -e

BASE_DIR="/opt/miner-lab/scripts"
TARGET="$BASE_DIR/xmrig-autotune.sh"

echo "🔧 Installing xmrig-autotune helper..."

mkdir -p "$BASE_DIR"

curl -fsSL https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main/scripts/xmrig-autotune.sh -o "$TARGET"
chmod +x "$TARGET"

echo "✅ xmrig-autotune installed to $TARGET"