# **Miner-Lab**

A modular, self-installing mining automation suite for Debian-based systems.  
Provides automatic monitoring, reporting, and maintenance for XMRig-based rigs.

---

## **📦 Components**
| Service | Function |
|----------|-----------|
| miner-syncd | Core environment and Pushcut sync daemon |
| xmrig-summary | Daily Pushcut summary of rig performance |
| xmrig-watchdog | Continuous health monitor and auto-restart |
| xmrig-autotune | Optional performance optimizer |

---

## **🧱 Installers**
Each service can be installed individually:

```bash
curl -fsSL https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main/install-scripts/install-miner-syncd.sh | bash
curl -fsSL https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main/install-scripts/install-xmrig-summary.sh | bash
curl -fsSL https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main/install-scripts/install-xmrig-watchdog.sh | bash
```

---

## **🧰 Utilities**
- xmrig-autotune.sh → optional tuning helper
- logrotate.d-miner-lab → rotates and compresses all miner-lab logs
- example.env → environment template for manual configuration

---

## **🧩 Requirements**
flask
requests
psutil
(Automatically Installed via venv during setup)

---

## **📖 Docs**
- /docs/README.md → developer notes and architecture
- /CHANGELOG.md → release tracking

---

### 🧾 `/LICENSE`
```text
MIT License

Copyright (c) 2025 Justin Farry

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: [...]

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
```

