#!/bin/bash

# Find the next available port pair starting from 5901
find_next_ports() {
    local vnc_port=5901
    local novnc_port=6080
    while nc -z localhost $vnc_port 2>/dev/null || nc -z localhost $novnc_port 2>/dev/null; do
        vnc_port=$((vnc_port + 1))
        novnc_port=$((novnc_port + 1))
    done
    echo "$vnc_port $novnc_port"
}

# Get next available ports
read vnc_port novnc_port <<< $(find_next_ports)

# Generate a random ID for the container
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 12 | head -n 1)

# Launch the container with Traefik labels
CONTAINER_ID=$(docker run -d \
    --rm \
    --gpus all \
    --privileged \
    --network dreamslab \
    -p ${vnc_port}:5901 \
    -p ${novnc_port}:6080 \
    -e DISPLAY=:1 \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -l "traefik.enable=true" \
    -l "traefik.http.routers.openuav-${RANDOM_ID}.rule=Host(\`digital-twin-${RANDOM_ID}.deepgis.org\`)" \
    -l "traefik.http.services.openuav-${RANDOM_ID}.loadbalancer.server.port=6080" \
    openuav:px4-sitl)

# Get short container ID
SHORT_ID=${CONTAINER_ID:0:12}

# Output container info in JSON format for the portal
echo "{\"container_id\": \"${CONTAINER_ID}\", \"short_id\": \"${SHORT_ID}\", \"vnc_port\": ${vnc_port}, \"novnc_port\": ${novnc_port}, \"url\": \"http://digital-twin-${RANDOM_ID}.deepgis.org\"}" 