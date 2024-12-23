#!/bin/bash

# Start VNC server
/opt/TurboVNC/bin/vncserver :1 -geometry 1920x1080 -depth 24

# Start noVNC
/opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 6080 &

# Wait for VNC to be fully started
sleep 2

# Start PX4 SITL
/root/launch_px4_sitl.sh 