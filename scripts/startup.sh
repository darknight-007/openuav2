#!/bin/bash

# Enable error handling and logging
set -e
exec 1> >(tee -a /var/log/openuav.log) 2>&1
echo "[$(date)] Starting OpenUAV container..."

# Clean up any existing processes
echo "[$(date)] Cleaning up existing processes..."
pkill -f vncserver || true
pkill -f Xvnc || true
pkill -f px4 || true
pkill -f gzserver || true
pkill -f gzclient || true

# Clean up X11 sockets but preserve the mount point
echo "[$(date)] Cleaning up X11 sockets..."
rm -f /tmp/.X* || true
rm -f /tmp/.x* || true

# Set permissions for X11 directory
echo "[$(date)] Setting up X11 directory..."
chmod 1777 /tmp/.X11-unix || true

# Start VNC server
echo "[$(date)] Starting VNC server..."
/opt/TurboVNC/bin/vncserver :1 -geometry 1920x1080 -depth 24
sleep 2

# Start noVNC
echo "[$(date)] Starting noVNC..."
/opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 6080 &
sleep 2

# Monitor critical processes
echo "[$(date)] Starting process monitor..."
while true; do
    # Check if VNC server is running
    if ! pgrep -f vncserver > /dev/null; then
        echo "[$(date)] WARNING: VNC server died, restarting..."
        /opt/TurboVNC/bin/vncserver :1 -geometry 1920x1080 -depth 24
    fi

    # Check if noVNC is running
    if ! pgrep -f novnc_proxy > /dev/null; then
        echo "[$(date)] WARNING: noVNC died, restarting..."
        /opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 6080 &
    fi

    sleep 5
done 