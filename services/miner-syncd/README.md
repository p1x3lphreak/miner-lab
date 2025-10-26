# **Miner-Syncd Service**

### **Overview**
`miner-syncd` is the core synchronization daemon of the Miner-Lab suite.  
It handles local environment updates, Pushcut notifications, and general coordination between mining scripts and systemd services.

---

### **🧱 Files**
| File | Description |
|------|--------------|
| `miner-syncd.service` | Systemd service definition for auto-start and supervision |
| `miner-syncd.py` | Python daemon that syncs stats and status updates |
| `install-miner-syncd.sh` | Installer for full environment + dependencies |

---

### **🔧 Service Management**
```bash
sudo systemctl enable miner-syncd.service
sudo systemctl start miner-syncd.service
sudo systemctl status miner-syncd.service
```
Logs:
```bash
sudo journalctl -u miner-syncd.service -f
```

---

### **🧰 Configuration**
Uses .env variables defined in /opt/miner-lab/config/.env or copied from example.env:
```bash
RIG_NAME="mutiny-srv-01"
PUSHCUT_SYNC_URL="https://api.pushcut.io/v1/notifications/miner-sync"
```

---

### **🧩 Notes**
- Runs automatically on boot once enabled.
- Communicates with the Pushcut API for real-time event triggers.
- Restart-safe via xmrig-watchdog postrotate hook.

---