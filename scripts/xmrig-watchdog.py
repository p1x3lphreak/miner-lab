#!/usr/bin/env python3
"""
Miner-Lab :: xmrig-watchdog.py
--------------------------------------------------
Monitors the xmrig process; restarts if not found or hung.
Logs actions to /var/log/xmrig-watchdog.log.
"""
import os, time, psutil, subprocess, datetime, requests

LOG_FILE = "/var/log/xmrig-watchdog.log"
TARGET_PROC = "xmrig"
RESTART_CMD = ["systemctl", "restart", "xmrig.service"]
CHECK_INTERVAL = 300  # 5 minutes
PUSHCUT_URL = os.getenv("PUSHCUT_WATCHDOG_URL")

def log(msg: str):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{ts}] {msg}\n")

def send_alert(msg: str):
    if not PUSHCUT_URL:
        return
    try:
        requests.post(PUSHCUT_URL, json={"title": "Watchdog Alert", "text": msg}, timeout=10)
    except Exception as e:
        log(f"Pushcut error: {e}")

def is_process_running(name: str):
    for proc in psutil.process_iter(attrs=["name"]):
        if name.lower() in proc.info["name"].lower():
            return True
    return False

def restart_miner():
    try:
        subprocess.run(RESTART_CMD, check=False)
        log("Restarted xmrig via systemctl")
        send_alert("⛏️ XMRig restarted by watchdog")
    except Exception as e:
        log(f"Failed to restart xmrig: {e}")

def main():
    log("Watchdog heartbeat started.")
    while True:
        if not is_process_running(TARGET_PROC):
            log("XMRig process not found — restarting...")
            restart_miner()
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()