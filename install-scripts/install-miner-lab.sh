#!/usr/bin/env bash
set -e
REPO="https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main"

echo "⚙️  Preparing miner-lab environment..."
sudo apt update -y && sudo apt install -y python3 python3-venv python3-pip curl logrotate

echo "📦 Installing services..."
for svc in miner-syncd xmrig-summary xmrig-watchdog; do
  echo "🚀 Deploying $svc..."
  bash <(curl -fsSL "$REPO/install-scripts/install-$svc.sh")
done

echo "🌀 Installing logrotate configuration..."
sudo curl -fsSL "$REPO/config/logrotate.d-miner-lab" \
  -o /etc/logrotate.d/miner-lab
sudo chown root:root /etc/logrotate.d/miner-lab
sudo chmod 644 /etc/logrotate.d/miner-lab

echo "✅ miner-lab installation complete!"