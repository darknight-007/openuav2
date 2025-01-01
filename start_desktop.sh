#!/bin/bash

# Function to get NVIDIA GPU BusID
get_gpu_busid() {
    nvidia-xconfig --query-gpu-info | grep "BusID" | awk '{print $4}'
}

# Function to wait for X server
wait_for_xserver() {
    for i in $(seq 1 10); do
        if xdpyinfo -display :1 >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    return 1
}

# Kill any existing processes
killall -9 Xorg x11vnc websockify xfce4-session 2>/dev/null
rm -rf /tmp/.X* /tmp/.x* /tmp/.vnc /tmp/.ICE-unix /tmp/.X11-unix
rm -f /run/dbus/pid
rm -f /tmp/.X1-lock

# Clean up and create necessary directories
mkdir -p /var/run/dbus
mkdir -p /root/.vnc
mkdir -p /tmp/.X11-unix
mkdir -p /tmp/.ICE-unix
chmod 1777 /tmp/.X11-unix /tmp/.ICE-unix

# Start D-Bus system daemon
dbus-daemon --system --fork

# Start D-Bus session daemon
dbus-daemon --session --address=unix:path=/tmp/dbus-session --fork

# Update xorg.conf with correct BusID
BUSID=$(get_gpu_busid)
if [ ! -z "$BUSID" ]; then
    sed -i "s/BusID.*/BusID      \"PCI:$BUSID\"/" /etc/X11/xorg.conf
fi

# Start X server with better options
Xorg :1 -config /etc/X11/xorg.conf -listen tcp -auth /root/.Xauthority &

# Wait for X server to start
if ! wait_for_xserver; then
    echo "Failed to start X server"
    exit 1
fi

# Set display and allow connections
export DISPLAY=:1
xhost +local:

# Set up environment variables
export DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/dbus-session
export XDG_RUNTIME_DIR=/tmp/runtime-dir
export XDG_SESSION_TYPE=x11
export XDG_SESSION_CLASS=user
export XDG_SESSION_DESKTOP=xfce
export XDG_CURRENT_DESKTOP=XFCE
export DESKTOP_SESSION=xfce
export XAUTHORITY=/root/.Xauthority

# Create runtime directory
mkdir -p /tmp/runtime-dir
chmod 700 /tmp/runtime-dir

# Start VNC server with better options
x11vnc -display :1 -auth /root/.Xauthority -forever -shared -rfbport 5901 -noxdamage -noxfixes -noxrecord -repeat -clear_keys &
sleep 2

# Start noVNC
websockify -D --web=/usr/share/novnc/ 6080 localhost:5901

# Ensure XFCE config directory exists
mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml

# Create default XFCE session config
cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-session" version="1.0">
  <property name="general" type="empty">
    <property name="FailsafeSessionName" type="string" value="Failsafe"/>
  </property>
  <property name="sessions" type="empty">
    <property name="Failsafe" type="empty">
      <property name="IsFailsafe" type="bool" value="true"/>
      <property name="Count" type="int" value="5"/>
      <property name="Client0_Command" type="array">
        <value type="string" value="xfwm4"/>
      </property>
      <property name="Client1_Command" type="array">
        <value type="string" value="xfce4-panel"/>
      </property>
      <property name="Client2_Command" type="array">
        <value type="string" value="Thunar"/>
      </property>
      <property name="Client3_Command" type="array">
        <value type="string" value="xfdesktop"/>
      </property>
      <property name="Client4_Command" type="array">
        <value type="string" value="xfce4-terminal"/>
      </property>
    </property>
  </property>
</channel>
EOF

# Create XFCE4 panel config
mkdir -p /root/.config/xfce4/panel
cat > /root/.config/xfce4/panel/default.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
      </property>
    </property>
  </property>
</channel>
EOF

# Start XFCE Session with logging
dbus-launch --exit-with-session startxfce4 > /var/log/xfce4.log 2>&1 &

# Wait for XFCE to start
sleep 5

# Source ROS and PX4 environment
source /opt/ros/foxy/setup.bash
source /root/PX4-Autopilot/Tools/setup_gazebo.bash /root/PX4-Autopilot /root/PX4-Autopilot/build/px4_sitl_default

# Export additional environment variables for Gazebo
export GAZEBO_MASTER_URI=http://localhost:11345
export GAZEBO_MODEL_DATABASE_URI=http://models.gazebosim.org
export GAZEBO_RESOURCE_PATH=/usr/share/gazebo-11
export GAZEBO_PLUGIN_PATH=/root/PX4-Autopilot/build/px4_sitl_default/build_gazebo
export GAZEBO_MODEL_PATH=/root/PX4-Autopilot/Tools/sitl_gazebo/models
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/PX4-Autopilot/build/px4_sitl_default/build_gazebo
export GAZEBO_GPU_RAY_TEXTURE_SIZE=2048
export LIBGL_DEBUG=verbose

# Keep container running and enter interactive shell if requested
if [ -t 0 ]; then
    bash
else
    # Monitor XFCE and VNC processes
    while true; do
        if ! pgrep -x "xfce4-session" > /dev/null || ! pgrep -x "x11vnc" > /dev/null; then
            echo "XFCE or VNC process died, restarting..."
            killall -9 xfce4-session x11vnc 2>/dev/null
            dbus-launch --exit-with-session startxfce4 > /var/log/xfce4.log 2>&1 &
            x11vnc -display :1 -auth /root/.Xauthority -forever -shared -rfbport 5901 -noxdamage -noxfixes -noxrecord -repeat -clear_keys &
        fi
        sleep 10
    done
fi 