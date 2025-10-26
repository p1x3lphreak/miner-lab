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

Compiled installer:

```bash
curl -fsSL https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main/install-scripts/install-miner-lab.sh | bash
```
see advanced options in next section for additional install options

---

### **🧠 Advanced Options** 
When running the installer manually (instead of via curl), you can enable additional flags to customize behavior:

|**Flag**|**Description**|**Example**| 
| --- | --- | --- |
|--force|Forces a full environment reconfiguration. Deletes the existing /etc/miner-lab.env file and re-prompts for rig name and Pushcut URLs.|bash install-miner-lab.sh --force|
|--with-autotune|Runs the xmrig-autotune.sh module immediately after setup to benchmark and optimize CPU thread performance for your miner.|bash install-miner-lab.sh --with-autotune|
|--force --with-autotune|Rebuilds the environment _and_ runs a fresh autotune pass (recommended for new or upgraded rigs).|bash install-miner-lab.sh --force --with-autotune|
Autotune results are stored within the Miner-Lab working directory and are automatically applied by future XMRig sessions.

---

### **🧩 Example: Full Reinstall with Autotune**
```bash
curl -fsSL https://raw.githubusercontent.com/p1x3lphreak/miner-lab/main/install-scripts/install-miner-lab.sh | bash -s -- --force --with-autotune
```
This command:
1. Removes any prior environment configuration.
2. Pulls all sub-installers and services from GitHub.
3. Deploys systemd units and logrotate.
4. Performs a one-time autotune benchmark for your CPU threads.

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

