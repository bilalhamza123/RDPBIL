#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=:1
export HOME="${HOME:-/home/vscode}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-vscode}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Start a virtual X desktop if it is not already running.
if ! pgrep -f "Xvfb :1" >/dev/null 2>&1; then
  rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
  Xvfb :1 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset >/tmp/rdpbil-xvfb.log 2>&1 &
  sleep 2
fi

# Start XFCE desktop session.
if ! pgrep -f "xfce4-session" >/dev/null 2>&1; then
  dbus-launch --exit-with-session startxfce4 >/tmp/rdpbil-xfce.log 2>&1 &
  sleep 4
fi

# VNC server exposes the virtual desktop locally only.
if ! pgrep -f "x11vnc.*5900" >/dev/null 2>&1; then
  x11vnc -display :1 -forever -shared -nopw -rfbport 5900 -localhost >/tmp/rdpbil-x11vnc.log 2>&1 &
  sleep 2
fi

# Prepare a noVNC web root that opens directly at the forwarded port.
NOVNC_ROOT=/tmp/rdpbil-novnc
mkdir -p "$NOVNC_ROOT"
if [ -f /usr/share/novnc/vnc.html ]; then
  cp -f /usr/share/novnc/vnc.html "$NOVNC_ROOT/index.html"
else
  echo "noVNC vnc.html not found" >&2
  exit 1
fi

# noVNC exposes the desktop through the Codespaces forwarded port.
if ! pgrep -f "websockify.*6080" >/dev/null 2>&1; then
  websockify --web="$NOVNC_ROOT" 6080 localhost:5900 >/tmp/rdpbil-novnc.log 2>&1 &
  sleep 2
fi

echo "RDPBIL desktop is ready."
echo "Open forwarded port 6080 to use the XFCE desktop in your browser."
