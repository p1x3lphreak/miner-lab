#!/usr/bin/env python3
"""
XMRig Summary Notifier
----------------------
Triggered daily by systemd timer.
Collects summary data (hashrate, uptime, or local stats)
and sends a Pushcut notification or webhook message.
"""

import os
import json
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
SUMMARY_SOURCE = os.getenv("SUMMARY_SOURCE", "/var/log/miner-lab/xmrig.log")
HOSTNAME = os.getenv("HOSTNAME", os.uname().nodename)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
LOG_PATH = "/var/log/miner-lab"
os.makedirs(LOG_PATH, exist_ok=True)
LOG_FILE = os.path.join(LOG_PATH, "xmrig-summary.log")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ],
)

# ---------------------------------------------------------------------------
# Summary Logic
# ---------------------------------------------------------------------------
def collect_summary():
    """Extract a summary snapshot from miner logs or metrics file."""
    try:
        if not os.path.exists(SUMMARY_SOURCE):
            logging.warning(f"Summary source not found: {SUMMARY_SOURCE}")
            return {"status": "no data"}

        # simple heuristic: look for 'hashrate' line
        hashrate = None
        with open(SUMMARY_SOURCE, "r") as f:
            for line in reversed(f.readlines()):
                if "hashrate" in line.lower():
                    hashrate = line.strip()
                    break

        return {
            "host": HOSTNAME,
            "timestamp": datetime.now().isoformat(),
            "hashrate": hashrate or "unknown",
        }
    except Exception as e:
        logging.exception(f"Error collecting summary: {e}")
        return {"error": str(e)}


def push_summary(data):
    """Send summary to Pushcut or external endpoint."""
    if not PUSHCUT_KEY:
        logging.warning("No PUSHCUT_KEY configured; skipping Pushcut push.")
        return

    try:
        payload = {
            "title": f"Miner Summary — {data.get('host')}",
            "text": f"Hashrate: {data.get('hashrate')}\nTime: {data.get('timestamp')}",
        }
        url = f"https://api.pushcut.io/v1/notifications/{PUSHCUT_KEY}"
        resp = requests.post(url, json=payload, timeout=10)

        if resp.status_code == 200:
            logging.info("Summary successfully sent to Pushcut.")
        else:
            logging.error(f"Pushcut returned {resp.status_code}: {resp.text[:100]}")
    except Exception as e:
        logging.exception(f"Failed to send summary: {e}")


def main():
    logging.info("Starting XMRig summary generation...")
    data = collect_summary()
    push_summary(data)
    logging.info("Summary task completed.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.exception(f"Unhandled error: {e}")