# RDPBIL — GitHub Codespaces 16GB Desktop

This configuration requests a Codespace with a minimum of 4 CPU cores, 16 GB RAM, and 64 GB storage.

## Desktop

The container starts an XFCE Linux desktop inside a virtual X server and exposes it through noVNC on port 6080. The port is configured as private, so access remains authenticated through GitHub.

After the Codespace starts:
1. Open the **PORTS** tab.
2. Find **6080 — RDPBIL Linux Desktop (noVNC)**.
3. Open the forwarded URL.
4. The XFCE desktop appears in the browser.

## Development tools

The environment includes Node.js 22, Python 3.12, GitHub CLI, Git, build tools, terminal utilities, Thunar file manager, Mousepad editor, and common VS Code extensions.

## Important

This is a Codespace development environment, not an unlimited-duration Windows RDP server. Codespaces can stop when idle and usage is subject to GitHub account/billing limits.
