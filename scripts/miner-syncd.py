#!/usr/bin/env python3
"""
Miner-Lab Sync Daemon
---------------------
Primary background daemon that monitors local miner state and
pushes summarized data to a configured endpoint or Pushcut webhook.

Runs continuously under systemd (Type=simple).
"""

import os
import time
import logging
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
SYNC_INTERVAL = int(os.getenv("SYNC_INTERVAL", "300"))
HOSTNAME = os.getenv("HOSTNAME", os.uname().nodename)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
LOG_PATH = "/var/log/miner-lab"
os.makedirs(LOG_PATH, exist_ok=True)

LOG_FILE = os.path.join(LOG_PATH, "miner-syncd.log")
ERR_FILE = os.path.join(LOG_PATH, "miner-syncd.err")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ],
)

# ---------------------------------------------------------------------------
# Core Functions
# ---------------------------------------------------------------------------
def push_update():
    """Send miner status to Pushcut or configured webhook."""
    try:
        if not PUSHCUT_KEY:
            logging.warning("No PUSHCUT_KEY configured; skipping push.")
            return

        payload = {
            "title": "Miner Sync Update",
            "text": f"Node: {HOSTNAME} — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        }
        url = f"https://api.pushcut.io/v1/notifications/{PUSHCUT_KEY}"
        resp = requests.post(url, json=payload, timeout=10)
        if resp.status_code == 200:
            logging.info("Successfully sent sync update to Pushcut.")
        else:
            logging.error(f"Pushcut returned {resp.status_code}: {resp.text[:100]}")
    except Exception as e:
        logging.exception(f"Sync push failed: {e}")


def main():
    """Main daemon loop."""
    logging.info("Miner Sync Daemon started.")
    while True:
        push_update()
        time.sleep(SYNC_INTERVAL)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logging.info("Miner Sync Daemon stopped by user.")
    except Exception as e:
        logging.exception(f"Unhandled exception: {e}")