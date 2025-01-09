#!/bin/bash -x

# Start XVnc/X/Lubuntu
chmod -f 777 /tmp/.X11-unix
rm -rf /tmp/.X*-lock
rm -rf /tmp/.X11-unix/X1  # Clean only VNC socket, leave GPU socket (:0) alone

# Setup X authority
touch ~/.Xauthority
chmod 600 ~/.Xauthority

# Initialize GPU display for GLX
nvidia-xconfig --allow-empty-initial-configuration --use-display-device=None --virtual=1920x1080 --busid $(nvidia-xconfig --query-gpu-info | grep 'PCI BusID' | cut -d ' ' -f 4)
X :0 &
sleep 2

# Start TurboVNC explicitly on :1 (while :0 is for GPU/GLX)
/opt/TurboVNC/bin/vncserver :1 -SecurityTypes None -xstartup /root/.vnc/xstartup.turbovnc

# Now that displays exist, set up auth
xauth add :0 . $(mcookie)
xauth add :1 . $(mcookie)

# Start NoVNC with proper hostname handling
if [ $? -eq 0 ] ; then
    HOSTNAME=$(hostname -i || echo "localhost")
    echo "You can access the desktop at: http://$HOSTNAME:40001/vnc.html"
    /opt/noVNC/utils/launch.sh --vnc localhost:5901 --cert /root/self.pem --listen 40001
fi