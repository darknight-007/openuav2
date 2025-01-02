#!/bin/bash

# Find the next available port pair starting from 5901
find_next_ports() {
    local vnc_port=5901
    while nc -z localhost $vnc_port 2>/dev/null; do
        vnc_port=$((vnc_port + 1))
    done
    echo "$vnc_port"
}

# Find next available display number
find_next_display() {
    local display=1
    mkdir -p "/tmp/openuav/displays"
    
    # Clean up stale display files
    for display_file in /tmp/openuav/displays/*; do
        if [ -f "$display_file" ]; then
            container_id=$(cat "$display_file")
            if ! docker ps -q -f id="$container_id" > /dev/null 2>&1; then
                rm -f "$display_file"
            fi
        fi
    done
    
    # Find next available display number
    while [ -e "/tmp/openuav/displays/${display}" ]; do
        display=$((display + 1))
    done
    
    echo "$display"
}

# Get next available port and display
vnc_port=$(find_next_ports)
display_num=$(find_next_display)

# Generate a random ID for the container
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 12 | head -n 1)

# Create container-specific directories
mkdir -p "/tmp/openuav/displays/${display_num}"
mkdir -p "/tmp/openuav/dbus/${display_num}"

# Launch the container
CONTAINER_ID=$(docker run -d \
    --rm \
    --init \
    --runtime=nvidia \
    --privileged \
    --network dreamslab \
    -p ${vnc_port}:5901 \
    -e DISPLAY=:${display_num} \
    -e NVIDIA_VISIBLE_DEVICES=1 \
    -e NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute \
    -e VGL_DISPLAY=/dev/dri/card0 \
    -e VNC_DISPLAY=${display_num} \
    -e DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-session-${display_num}" \
    -v "/tmp/openuav/displays/${display_num}:/tmp/.X11-unix" \
    -v "/tmp/openuav/dbus/${display_num}:/tmp/dbus-session-${display_num}" \
    --device=/dev/dri:/dev/dri \
    --name "digital-twin-${RANDOM_ID}" \
    openuav:px4-sitl)

# Get short container ID
SHORT_ID=${CONTAINER_ID:0:12}

# Record container's display number
echo "$CONTAINER_ID" > "/tmp/openuav/displays/${display_num}"

# Output container info in JSON format for the portal
echo "{
    \"container_id\": \"${CONTAINER_ID}\",
    \"short_id\": \"${SHORT_ID}\",
    \"vnc_port\": ${vnc_port},
    \"display\": ${display_num},
    \"url\": \"https://digital-twin-${RANDOM_ID}.deepgis.org\",
    \"vnc_url\": \"vnc://digital-twin-${RANDOM_ID}.deepgis.org:${vnc_port}\"
}" 