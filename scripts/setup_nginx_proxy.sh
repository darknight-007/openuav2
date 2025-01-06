#!/bin/bash

# Exit on error
set -e

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please run setup_host.sh first."
    exit 1
fi

# Create network if it doesn't exist
docker network create --driver bridge dreamslab || true

# Create basic nginx config for container
mkdir -p /tmp/nginx-proxy-conf
cat > /tmp/nginx-proxy-conf/nginx.conf << 'EOF'
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    # Docker DNS resolver
    resolver 127.0.0.11 valid=2s;

    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }   

    server {
        listen 80;
        
        # Digital Twin subdomain configuration
        location / {
            # Extract container name from Host header
            if ($http_host ~ ^digital-twin-(?<container_id>[a-zA-Z0-9-]+)) {
                set $target_container $container_id;
            }
            
            # Proxy to the container's noVNC port
            proxy_pass http://digital-twin-$target_container:6080;
            
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_read_timeout 61s;
            proxy_buffering off;
        }
    }
}
EOF

# Stop and remove existing nginx-proxy container if it exists
if docker ps -a | grep -q nginx-proxy; then
    echo "Stopping and removing existing nginx-proxy container..."
    docker stop nginx-proxy || true
    docker rm nginx-proxy || true
fi

# Start Nginx container
echo "Starting nginx-proxy container..."
docker run -d \
    --name nginx-proxy \
    --network dreamslab \
    --restart unless-stopped \
    -p 127.0.0.1:6080:80 \
    -v /tmp/nginx-proxy-conf/nginx.conf:/etc/nginx/nginx.conf:ro \
    nginx:latest

echo "Nginx proxy container setup completed successfully!
Note: Configure your host's nginx to proxy *.deepgis.org to localhost:6080" 