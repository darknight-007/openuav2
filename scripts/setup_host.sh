#!/bin/bash

# Exit on error
set -e

# Update package lists
apt-get update

# Install basic dependencies
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    xorg \
    x11-xserver-utils \
    xauth

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
fi

# Create required directories in user's home
mkdir -p $HOME/openuav_data/displays
mkdir -p $HOME/openuav_data/dbus
mkdir -p $HOME/openuav_data/x11

# Set proper permissions
chmod -R 700 $HOME/openuav_data

# Configure xhost access
if [ -n "$DISPLAY" ]; then
    xhost +local:root || true
    xhost +local:docker || true
fi

# Set up DNS for .deepgis.org subdomain resolution
cat >> /etc/hosts << EOF
127.0.0.1 deepgis.org
127.0.0.1 *.deepgis.org
EOF

# Create xhost startup script in user's home
mkdir -p $HOME/.config/autostart
cat > $HOME/.config/autostart/xhost-setup.desktop << EOF
[Desktop Entry]
Type=Application
Name=XHost Setup
Exec=bash -c 'if [ -n "$DISPLAY" ]; then xhost +local:root; xhost +local:docker; fi'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

chmod +x $HOME/.config/autostart/xhost-setup.desktop

echo "Host setup completed successfully!
Note: X11 socket directory and xhost access have been configured for container display access." 
