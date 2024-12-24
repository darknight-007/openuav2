#!/bin/bash

# Clean up any existing VNC servers on host
pkill -f vncserver || true
pkill -f Xvnc || true
sudo rm -rf /tmp/.X* /tmp/.x*

# Create and set permissions for X11 directory
sudo mkdir -p /tmp/.X11-unix
sudo chmod 1777 /tmp/.X11-unix

# Run the PX4 SITL container with necessary parameters
docker run -it --rm \
    --name openuav_px4 \
    --privileged \
    --env="DISPLAY=$DISPLAY" \
    --env="QT_X11_NO_MITSHM=1" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --runtime=nvidia \
    -p 6080:6080 \
    -p 5901:5901 \
    openuav:px4-sitl 