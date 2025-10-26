#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
miner-syncd_v2.2.py
--------------------
OmniCore Mining Node Telemetry Daemon
Handles runtime sync, health monitoring, Pushcut alerts, and periodic summaries.
Author: Justin Farry (p1x3lphreak)
Version: 2.2 - October 2025
"""

import os
import json
import time
import psutil
import logging
import platform
import subprocess
from datetime import datetime, timedelta
from http.server import BaseHTTPRequestHandler, HTTPServer
from threading import Thread
import requests

# ------------------ CONFIG ------------------
LOG_FILE = "/var/log/miner-syncd.log"
HOST_NAME = "0.0.0.0"
PORT_NUMBER = 8088

PUSHCUT_URL_ALERT = os.getenv("PUSHCUT_URL_ALERT")
PUSHCUT_URL_SUMMARY = os.getenv("PUSHCUT_URL_SUMMARY")

# ------------------ LOGGING SETUP ------------------
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)

def log(msg):  # wrapper for both stdout and file
    print(msg)
    logging.info(msg)

# ------------------ SYSTEM METRICS ------------------
def get_cpu_temp():
    try:
        thermal_zones = [f"/sys/class/thermal/thermal_zone{i}/temp" for i in range(0, 10)]
        for zone in thermal_zones:
            if os.path.exists(zone):
                with open(zone, "r") as f:
                    return round(int(f.readline().strip()) / 1000, 1)
    except Exception:
        pass
    return None

def get_uptime():
    try:
        uptime_seconds = time.time() - psutil.boot_time()
        return str(timedelta(seconds=int(uptime_seconds)))
    except Exception:
        return "unknown"

def get_memory_usage():
    mem = psutil.virtual_memory()
    return {"used": mem.used // (1024 * 1024), "total": mem.total // (1024 * 1024)}

def get_load_avg():
    try:
        return os.getloadavg()
    except Exception:
        return (0, 0, 0)

# ------------------ MINER METRICS ------------------
def get_miner_stats():
    """Pulls data from xmrig JSON API if available."""
    try:
        import socket
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1)
        s.connect(("127.0.0.1", 8080))
        s.sendall(b'{"method":"summary"}\n')
        data = s.recv(4096)
        s.close()
        j = json.loads(data)
        hashrate = j.get("hashrate", {}).get("total", [0])[0]
        return {"hashrate": hashrate, "ver": j.get("version", "unknown")}
    except Exception:
        return {"hashrate": 0, "ver": "unreachable"}

# ------------------ PUSHCUT HANDLERS ------------------
def pushcut_notify(title, text, url):
    if not url:
        log("⚠️ Pushcut URL not configured.")
        return
    try:
        payload = {"title": title, "text": text}
        requests.post(url, json=payload, timeout=5)
        log(f"📤 Pushcut sent: {title}")
    except Exception as e:
        log(f"❌ Pushcut failed: {e}")

# ------------------ HEALTH API SERVER ------------------
class MinerHandler(BaseHTTPRequestHandler):
    def _send_json(self, data, code=200):
        self.send_response(code)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_GET(self):
        if self.path == "/api/health":
            cpu_temp = get_cpu_temp()
            miner = get_miner_stats()
            data = {
                "status": "ok",
                "uptime": get_uptime(),
                "cpu_temp": cpu_temp,
                "load_avg": get_load_avg(),
                "memory": get_memory_usage(),
                "hashrate": miner["hashrate"],
                "miner_version": miner["ver"],
            }
            self._send_json(data)
        elif self.path == "/api/summary":
            data = generate_summary()
            self._send_json(data)
        else:
            self._send_json({"error": "Invalid endpoint"}, code=404)

def run_server():
    httpd = HTTPServer((HOST_NAME, PORT_NUMBER), MinerHandler)
    log(f"🌐 miner-syncd API running on port {PORT_NUMBER}")
    httpd.serve_forever()

# ------------------ SUMMARY REPORT ------------------
def generate_summary():
    miner = get_miner_stats()
    uptime = get_uptime()
    cpu_temp = get_cpu_temp()
    memory = get_memory_usage()
    load_avg = get_load_avg()

    summary = {
        "timestamp": datetime.utcnow().isoformat(),
        "system": platform.node(),
        "uptime": uptime,
        "cpu_temp": cpu_temp,
        "memory_used_MB": memory["used"],
        "memory_total_MB": memory["total"],
        "load_avg": load_avg,
        "hashrate": miner["hashrate"],
        "miner_version": miner["ver"],
    }
    return summary

def pushcut_daily_summary():
    """Send daily summary to Pushcut Miner-Summary endpoint"""
    data = generate_summary()
    msg = (
        f"📊 Miner Summary ({data['system']})\n"
        f"⏱ Uptime: {data['uptime']}\n"
        f"💨 Hashrate: {data['hashrate']} H/s\n"
        f"🌡 CPU Temp: {data['cpu_temp']}°C\n"
        f"🧠 RAM: {data['memory_used_MB']}MB / {data['memory_total_MB']}MB\n"
        f"📦 Load Avg: {data['load_avg']}\n"
    )
    pushcut_notify("Daily Miner Summary", msg, PUSHCUT_URL_SUMMARY)

# ------------------ MAIN ------------------
if __name__ == "__main__":
    log("🚀 Starting miner-syncd v2.2 daemon...")
    Thread(target=run_server, daemon=True).start()

    last_summary = None
    while True:
        now = datetime.now()
        if last_summary is None or (now - last_summary).seconds > 86400:
            pushcut_daily_summary()
            last_summary = now

        miner = get_miner_stats()
        if miner["hashrate"] == 0:
            pushcut_notify("⚠️ Miner Offline", "Hashrate dropped to zero.", PUSHCUT_URL_ALERT)
        time.sleep(300)