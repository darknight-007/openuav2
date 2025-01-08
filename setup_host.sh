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

# Create required directories
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

# Start dedicated X server for OpenUAV
cat > /usr/local/bin/start_openuav_xserver.sh << EOF
#!/bin/bash
/usr/lib/xorg/Xorg -core :0 \
    -isolateDevice PCI:82:0:0 \
    -config /etc/X11/xorg.conf.gpu2 \
    -noreset vt1
EOF

chmod +x /usr/local/bin/start_openuav_xserver.sh

# Create systemd service for OpenUAV X server
cat > /etc/systemd/system/openuav-xserver.service << EOF
[Unit]
Description=OpenUAV X Server
After=network.target

[Service]
ExecStart=/usr/local/bin/start_openuav_xserver.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl enable openuav-xserver
systemctl start openuav-xserver

echo "Host setup completed successfully!"
echo "Note: X11 socket directory and xhost access have been configured for container display access." 