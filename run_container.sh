#!/bin/bash

# Find next available display number
find_next_display() {
    local display=1
    local OPENUAV_DIR="$HOME/.openuav"
    
    # Create OpenUAV directories if they don't exist
    mkdir -p "$OPENUAV_DIR"/{displays,x11,dbus,logs}
    chmod 700 "$OPENUAV_DIR"
    chmod 700 "$OPENUAV_DIR"/{displays,x11,dbus,logs}
    
    # Clean up stale display files
    for display_file in "$OPENUAV_DIR/displays"/*; do
        if [ -f "$display_file" ]; then
            container_id=$(cat "$display_file")
            if ! docker ps -q -f id="$container_id" > /dev/null 2>&1; then
                rm -f "$display_file"
            fi
        fi
    done
    
    # Find next available display number
    while [ -e "$OPENUAV_DIR/displays/${display}" ]; do
        display=$((display + 1))
    done
    
    echo "$display"
}

# Get next available display number
display_num=$(find_next_display)

# Generate a random ID for the container
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 12 | head -n 1)

# Get current user's UID and GID
USER_UID=$(id -u)
USER_GID=$(id -g)

# Create container-specific directories
OPENUAV_DIR="$HOME/.openuav"
mkdir -p "$OPENUAV_DIR/x11/${display_num}"
mkdir -p "$OPENUAV_DIR/dbus/${display_num}"
chmod 700 "$OPENUAV_DIR/x11/${display_num}"
chmod 700 "$OPENUAV_DIR/dbus/${display_num}"

# Launch the container
CONTAINER_ID=$(docker run --rm \
    --init \
    --runtime=nvidia \
    --privileged \
    --network dreamslab \
    -e DISPLAY=:${display_num} \
    -e NVIDIA_VISIBLE_DEVICES=1 \
    -e NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute \
    -e VGL_DISPLAY=/dev/dri/card0 \
    -e VNC_DISPLAY=${display_num} \
    -e DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-session-${display_num}" \
    -e USER_UID="$USER_UID" \
    -e USER_GID="$USER_GID" \
    -v "$OPENUAV_DIR/x11/${display_num}:/tmp/.X11-unix" \
    -v "$OPENUAV_DIR/dbus/${display_num}:/tmp/dbus-session-${display_num}" \
    -v "$OPENUAV_DIR/logs:/var/log/openuav" \
    --device=/dev/dri:/dev/dri \
    --name "digital-twin-${RANDOM_ID}" \
    openuav:px4-sitl)

# Get short container ID
SHORT_ID=${CONTAINER_ID:0:12}

# Record container's display number
echo "$CONTAINER_ID" > "$OPENUAV_DIR/displays/${display_num}"

# Set proper ownership of the OpenUAV directories
chown -R $USER_UID:$USER_GID "$OPENUAV_DIR"

# Output container info in JSON format for the portal
echo "{
    \"container_id\": \"${CONTAINER_ID}\",
    \"short_id\": \"${SHORT_ID}\",
    \"display\": ${display_num},
    \"url\": \"https://digital-twin-${RANDOM_ID}.deepgis.org\",
}" 