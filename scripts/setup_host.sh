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
mkdir -p /tmp/openuav/displays
mkdir -p /tmp/openuav/dbus
mkdir -p /tmp/.X11-unix

# Set proper permissions for X11 socket directory
chmod 1777 /tmp/.X11-unix

# Configure xhost access control
xhost +local:root || true
xhost +local:docker || true

# Set up DNS for .deepgis.org subdomain resolution
cat >> /etc/hosts << EOF
127.0.0.1 deepgis.org
127.0.0.1 *.deepgis.org
EOF

# Create xhost startup script
cat > /etc/profile.d/xhost-local.sh << 'EOF'
#!/bin/bash
if [ -n "$DISPLAY" ]; then
    xhost +local:root > /dev/null 2>&1
    xhost +local:docker > /dev/null 2>&1
fi
EOF

chmod +x /etc/profile.d/xhost-local.sh

echo "Host setup completed successfully!
Note: X11 socket directory and xhost access have been configured for container display access." 