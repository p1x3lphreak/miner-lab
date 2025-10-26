#!/usr/bin/env python3
"""
Miner-Lab :: xmrig-summary.py
-------------------------------------
Collects mining stats and pushes a daily summary to Pushcut.
"""
import os, json, requests, subprocess, datetime

ENV_FILE = "/etc/miner-syncd.env"
CONFIG_FILE = "/etc/miner-syncd/config.json"
LOG_FILE = "/var/log/xmrig-summary.log"

def load_env():
    env = {}
    with open(ENV_FILE) as f:
        for line in f:
            if "=" in line:
                k, v = line.strip().split("=", 1)
                env[k] = v.strip('"')
    return env

def load_config():
    try:
        with open(CONFIG_FILE) as f:
            return json.load(f)
    except FileNotFoundError:
        return {"miners": []}

def get_hashrate():
    try:
        cmd = ["xmrig", "--version"]
        out = subprocess.check_output(cmd, text=True)
        return "Active" if out else "Unknown"
    except Exception:
        return "Offline"

def push_summary(env, stats):
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    data = {
        "title": f"⛏️ {env.get('RIG_NAME', 'Miner-Lab')} Daily Summary",
        "text": json.dumps(stats, indent=2),
        "timestamp": now
    }
    try:
        requests.post(env["PUSHCUT_SUMMARY_URL"], json=data, timeout=10)
    except Exception as e:
        with open(LOG_FILE, "a") as log:
            log.write(f"[{now}] Pushcut error: {e}\n")

def main():
    env = load_env()
    cfg = load_config()
    stats = {
        "rig": env.get("RIG_NAME", "mine-lab"),
        "miners": cfg.get("miners", []),
        "status": get_hashrate(),
        "timestamp": datetime.datetime.now().isoformat()
    }
    push_summary(env, stats)

if __name__ == "__main__":
    main()