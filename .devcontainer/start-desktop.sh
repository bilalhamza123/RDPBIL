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

# Prepare a complete noVNC web root, including all JS/CSS/assets.
NOVNC_ROOT=/tmp/rdpbil-novnc
rm -rf "$NOVNC_ROOT"
mkdir -p "$NOVNC_ROOT"
if [ -d /usr/share/novnc ]; then
  cp -a /usr/share/novnc/. "$NOVNC_ROOT/"
else
  echo "noVNC directory not found" >&2
  exit 1
fi

# Open noVNC directly at the forwarded port root.
cp -f "$NOVNC_ROOT/vnc.html" "$NOVNC_ROOT/index.html"

# Start websockify if it is not already listening.
if ! pgrep -f "websockify.*6080.*localhost:5900" >/dev/null 2>&1; then
  websockify --web="$NOVNC_ROOT" 6080 localhost:5900 >/tmp/rdpbil-novnc.log 2>&1 &
  sleep 3
fi

echo "RDPBIL desktop is ready."
echo "XFCE: :1 | VNC: localhost:5900 | noVNC: http://localhost:6080"
