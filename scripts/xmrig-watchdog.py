#!/usr/bin/env python3
"""
XMRig Watchdog Monitor
----------------------
Continuously checks if the XMRig process is running.
If not, attempts to restart and logs the event.

Runs indefinitely under systemd (Type=simple).
"""

import os
import time
import subprocess
import logging
import psutil
import requests
from datetime import datetime
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
ENV_FILE = "/etc/miner-lab/.env"
if os.path.exists(ENV_FILE):
    load_dotenv(ENV_FILE)

PUSHCUT_KEY = os.getenv("PUSHCUT_KEY", "")
XMRIG_PATH = os.getenv("XMRIG_PATH", "/usr/local/bin/xmrig")
CHECK_INTERVAL = int(os.getenv("WATCHDOG_INTERVAL", "60"))
HOSTNAME = os.getenv("HOSTNAME", os.uname().nodename)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
LOG_PATH = "/var/log/miner-lab"
os.makedirs(LOG_PATH, exist_ok=True)
LOG_FILE = os.path.join(LOG_PATH, "xmrig-watchdog.log")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ],
)

# ---------------------------------------------------------------------------
# Utility Functions
# ---------------------------------------------------------------------------
def push_alert(message: str):
    """Send an alert to Pushcut or log if disabled."""
    if not PUSHCUT_KEY:
        logging.warning(f"Pushcut not configured; alert: {message}")
        return
    try:
        payload = {"title": "XMRig Watchdog", "text": f"{HOSTNAME}: {message}"}
        url = f"https://api.pushcut.io/v1/notifications/{PUSHCUT_KEY}"
        resp = requests.post(url, json=payload, timeout=10)
        if resp.status_code == 200:
            logging.info("Alert sent to Pushcut.")
        else:
            logging.error(f"Pushcut returned {resp.status_code}: {resp.text[:100]}")
    except Exception as e:
        logging.exception(f"Pushcut alert failed: {e}")


def is_xmrig_running() -> bool:
    """Check if an XMRig process is active."""
    for proc in psutil.process_iter(attrs=["name", "exe", "cmdline"]):
        try:
            if "xmrig" in proc.info["name"].lower():
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    return False


def restart_xmrig():
    """Attempt to start XMRig if not running."""
    try:
        subprocess.Popen([XMRIG_PATH], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        logging.warning("XMRig process restarted.")
        push_alert("XMRig was not running — restarted successfully.")
    except Exception as e:
        logging.exception(f"Failed to restart XMRig: {e}")
        push_alert(f"Failed to restart XMRig: {e}")


def main():
    logging.info("XMRig Watchdog started.")
    while True:
        if not is_xmrig_running():
            logging.warning("XMRig process not detected.")
            restart_xmrig()
        time.sleep(CHECK_INTERVAL)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logging.info("Watchdog stopped manually.")
    except Exception as e:
        logging.exception(f"Unhandled exception: {e}")