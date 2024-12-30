#!/bin/bash

# Start VNC server
/opt/TurboVNC/bin/vncserver :1 -geometry 1920x1080 -depth 24 -rfbport 5901

# Start noVNC
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080 &

# Keep the container running
tail -f /dev/null 