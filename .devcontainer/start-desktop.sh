#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=:1
export HOME="${HOME:-/home/vscode}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-vscode}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

log() {
  echo "[RDPBIL] $*"
}

# Start Xvfb.
if ! pgrep -f "Xvfb :1" >/dev/null 2>&1; then
  rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
  Xvfb :1 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset     >/tmp/rdpbil-xvfb.log 2>&1 &
  sleep 3
fi

# Start XFCE.
if ! pgrep -f "xfce4-session" >/dev/null 2>&1; then
  dbus-launch --exit-with-session startxfce4     >/tmp/rdpbil-xfce.log 2>&1 &
  sleep 5
fi

# Start VNC server on localhost:5900.
if ! pgrep -f "x11vnc.*rfbport 5900" >/dev/null 2>&1; then
  x11vnc -display :1 -forever -shared -nopw     -rfbport 5900 -localhost     >/tmp/rdpbil-x11vnc.log 2>&1 &
  sleep 3
fi

# Verify VNC is actually listening.
if ! (command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q ":5900 "); then
  log "x11vnc did not open port 5900."
  cat /tmp/rdpbil-x11vnc.log 2>/dev/null || true
  exit 1
fi

# Use the packaged noVNC assets.
NOVNC_ROOT=/tmp/rdpbil-novnc
rm -rf "$NOVNC_ROOT"
mkdir -p "$NOVNC_ROOT"

if [ ! -d /usr/share/novnc ]; then
  log "noVNC package directory not found."
  exit 1
fi

cp -a /usr/share/novnc/. "$NOVNC_ROOT/"

if [ ! -f "$NOVNC_ROOT/vnc.html" ]; then
  log "vnc.html not found in noVNC installation."
  exit 1
fi

cp -f "$NOVNC_ROOT/vnc.html" "$NOVNC_ROOT/index.html"

# Stop stale proxy processes from previous container starts.
pkill -f "websockify.*6080" >/dev/null 2>&1 || true
sleep 1

# Prefer the noVNC proxy helper when available; otherwise use websockify.
if command -v novnc_proxy >/dev/null 2>&1; then
  log "Starting novnc_proxy on 6080..."
  novnc_proxy --listen 6080 --vnc localhost:5900 --web "$NOVNC_ROOT"     >/tmp/rdpbil-novnc.log 2>&1 &
else
  log "Starting websockify on 6080..."
  websockify --web="$NOVNC_ROOT" 6080 localhost:5900     >/tmp/rdpbil-novnc.log 2>&1 &
fi

sleep 4

# Fail loudly instead of leaving Codespaces with an HTTP 502.
if ! (command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q ":6080 "); then
  log "noVNC proxy did not open port 6080."
  cat /tmp/rdpbil-novnc.log 2>/dev/null || true
  exit 1
fi

log "Desktop ready: XFCE :1, VNC localhost:5900, noVNC :6080"
