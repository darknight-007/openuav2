#!/bin/bash
set -e  # Exit on error

# Create log file
touch /var/log/startup.log
exec 1> >(tee -a /var/log/startup.log) 2>&1  # Log all output

echo "[$(date)] Starting container..."

# Kill any existing VNC or X servers
echo "[$(date)] Cleaning up existing processes..."
pkill -f vncserver || true
pkill -f Xvnc || true
pkill -f websockify || true
sleep 2  # Wait for processes to fully terminate

# Clean up any existing X11 locks
echo "[$(date)] Setting up X11..."
rm -rf /tmp/.X*-lock /tmp/.X11-unix/*
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Start TurboVNC server
echo "[$(date)] Starting TurboVNC server..."
if ! pgrep -f Xvnc > /dev/null; then
    /opt/TurboVNC/bin/vncserver :1 -geometry 1920x1080 -depth 24 -securitytypes none -xstartup /root/.vnc/xstartup
    sleep 3
fi

# Set up X authority
echo "[$(date)] Configuring X authority..."
touch /root/.Xauthority
xauth generate :1 . trusted
sleep 2

# Start noVNC
echo "[$(date)] Starting noVNC..."
if ! pgrep -f websockify > /dev/null; then
    websockify --web=/usr/share/novnc 6080 localhost:5901 &
    sleep 2
fi

# Test GPU capabilities with glxgears
echo "[$(date)] Testing GPU capabilities..."
if pgrep -f vncserver && pgrep -f websockify; then
    export DISPLAY=:1
    vglrun glxgears -info
fi

echo "[$(date)] Startup complete. Container is ready."

# Monitor critical processes and keep container running
while true; do
    # Check VNC server
    if ! pgrep -f Xvnc > /dev/null; then
        echo "[$(date)] WARNING: VNC server died, restarting..."
        rm -rf /tmp/.X*-lock /tmp/.X11-unix/* || true
        /opt/TurboVNC/bin/vncserver :1 -geometry 1920x1080 -depth 24 -securitytypes none -xstartup /root/.vnc/xstartup
        sleep 2
    fi

    # Check noVNC
    if ! pgrep -f websockify > /dev/null; then
        echo "[$(date)] WARNING: noVNC died, restarting..."
        websockify --web=/usr/share/novnc 6080 localhost:5901 &
        sleep 2
    fi

    # Keep container running and monitor logs
    tail -f /var/log/startup.log & wait
done