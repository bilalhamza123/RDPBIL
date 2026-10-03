FROM mcr.microsoft.com/devcontainers/base:ubuntu

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       xfce4 \
       xfce4-goodies \
       dbus-x11 \
       x11-xserver-utils \
       xvfb \
       x11vnc \
       novnc \
       websockify \
       thunar \
       mousepad \
       htop \
       tree \
       jq \
       unzip \
       zip \
       wget \
       curl \
       build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER vscode
WORKDIR /workspaces/RDPBIL
