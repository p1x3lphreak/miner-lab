# 🪙 Miner-Lab — Monero Mining Suite

![Final Validation](https://github.com/p1x3lphreak/miner-lab/actions/workflows/final-validation.yml/badge.svg)
![Release](https://github.com/p1x3lphreak/miner-lab/actions/workflows/release.yml/badge.svg)

A fully-automated Monero mining toolkit for Debian 13+, built for reliability and simplicity.  
Miner-Lab installs, configures, and manages your mining stack using **systemd** services and daily health checks.

---

## ✨ Features

- One-line install: `curl -fsSL https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main/install-scripts/install-miner-lab.sh | sudo bash`
- Modular daemons:
  - `miner-syncd` – Pushcut sync daemon  
  - `xmrig-summary` – Daily performance summary  
  - `xmrig-watchdog` – Auto-restart health monitor  
- Shared Python virtual env, unified logging, logrotate integration
- Tested automatically on clean **Debian 13 “Trixie”**

---

## ⚙️ Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main/install-scripts/install-miner-lab.sh | sudo bash
```

Post install, check services:
```bash
systemctl status miner-syncd
systemctl list-timers | grep xmrig
```

Logs live at /var/log/miner-lab/.
Edit environmental variables in /etc/miner-lab/ .env

---

## 🧱 Project Structure
```
/opt/miner-lab/
 ├── scripts/              # Python daemons + utilities
 ├── services/             # systemd service + timer units
 ├── config/               # logrotate + example.env
 ├── docs/                 # CHANGELOG.md, requirements.txt
 └── install-scripts/      # bootstrap + component installers
```

---

## 🧩 Development / Testing

To verify installation in CI or locally:
```bash
sudo ./install-scripts/install-miner-lab.sh
sudo systemctl daemon-reload
```
For development containers, see .github/workflows/final-validation.yml

---

## 📦 Releases & Changelog

See the [Releases](https://github.com/p1x3lphreak/miner-lab/releases) tab.
Each push to main automatically bumps version and publishes a changelog.

---

## 🧠 License

```
MIT License

Copyright (c) 2025 Justin Farry

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: [...]

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
```
