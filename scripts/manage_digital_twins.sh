#!/bin/bash

# Find next available display number
find_next_display() {
    local display=1
    mkdir -p "$HOME/openuav_data/displays"
    
    # Clean up stale display files
    for display_file in $HOME/openuav_data/displays/*; do
        if [ -f "$display_file" ]; then
            container_id=$(cat "$display_file")
            if ! docker ps -q -f id="$container_id" > /dev/null 2>&1; then
                rm -f "$display_file"
            fi
        fi
    done
    
    # Find next available display number
    while [ -e "$HOME/openuav_data/displays/${display}" ]; do
        display=$((display + 1))
    done
    
    echo "$display"
}

# Start a new digital twin container
start_digital_twin() {
    # Generate a random ID for the container
    local RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 12 | head -n 1)
    local display_num=$(find_next_display)
    
    # Create container-specific directories
    mkdir -p "$HOME/openuav_data/displays/${display_num}"
    mkdir -p "$HOME/openuav_data/dbus/${display_num}"
    
    # Launch the container
    CONTAINER_ID=$(docker run -d \
        --rm \
        --init \
        --network dreamslab \
        -e DISPLAY=:${display_num} \
        -e VNC_DISPLAY=${display_num} \
        -v "$HOME/openuav_data/displays/${display_num}:/tmp/.X11-unix" \
        -v "$HOME/openuav_data/dbus/${display_num}:/tmp/dbus-session-${display_num}" \
        --name "digital-twin-${RANDOM_ID}" \
        "$@")
    
    # Record container's display number
    echo "$CONTAINER_ID" > "$HOME/openuav_data/displays/${display_num}"
    
    # Output container info
    echo "{
    \"container_id\": \"${CONTAINER_ID}\",
    \"display\": ${display_num},
    \"url\": \"http://digital-twin-${RANDOM_ID}.deepgis.org\"
}"
}

# Stop a digital twin container
stop_digital_twin() {
    local container_id="$1"
    if [ -z "$container_id" ]; then
        echo "Error: Container ID required"
        return 1
    fi
    
    # Find and remove display file
    for display_file in $HOME/openuav_data/displays/*; do
        if [ -f "$display_file" ]; then
            if grep -q "$container_id" "$display_file"; then
                rm -f "$display_file"
                break
            fi
        fi
    done
    
    # Stop container
    docker stop "$container_id"
}

# List running digital twins
list_digital_twins() {
    echo "Running Digital Twins:"
    echo "----------------------"
    docker ps --filter "name=digital-twin-" --format "ID: {{.ID}}\nName: {{.Names}}\nStatus: {{.Status}}\nPorts: {{.Ports}}\n"
}

# Main command processing
case "$1" in
    start)
        shift
        start_digital_twin "$@"
        ;;
    stop)
        shift
        stop_digital_twin "$@"
        ;;
    list)
        list_digital_twins
        ;;
    *)
        echo "Usage: $0 {start|stop|list} [additional arguments for start]"
        echo "Examples:"
        echo "  $0 start your-container-image"
        echo "  $0 stop container_id"
        echo "  $0 list"
        exit 1
        ;;
esac 