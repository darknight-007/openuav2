#!/bin/bash -x

# Start XVnc/X/Lubuntu
chmod -f 777 /tmp/.X11-unix
rm -rf /tmp/.X*-lock
rm -rf /tmp/.X11-unix/*

# From: https://superuser.com/questions/806637/xauth-not-creating-xauthority-file (squashes complaints about .Xauthority)
touch ~/.Xauthority
xauth generate :${VNC_DISPLAY:-0} . trusted

# Configure VirtualGL for GPU 1
export VGL_DISPLAY=/dev/dri/card1

# Start TurboVNC with specific display
/opt/TurboVNC/bin/vncserver :${VNC_DISPLAY:-0} \
    -geometry 1920x1080 \
    -depth 24 \
    -vgl \
    -SecurityTypes None

# Start NoVNC. self.pem is a self-signed cert.
if [ $? -eq 0 ] ; then
    /opt/noVNC/utils/launch.sh --vnc localhost:${VNC_PORT:-5901} --cert /root/self.pem --listen ${NOVNC_PORT:-40001}
fi