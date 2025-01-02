# OpenUAV2 Container Architecture

This repository contains the containerized environment for OpenUAV simulations with GPU acceleration and web-based access.

## Display Stack Architecture

The OpenUAV container uses a sophisticated display stack to provide GPU-accelerated 3D graphics through a web browser. Here's how each component works together:

```
┌─────────────┐     ┌──────────┐     ┌───────────┐     ┌──────────┐     ┌───────┐     ┌───────┐     ┌──────────┐
│  NVIDIA GPU │ ──► │ X Server │ ──► │ VirtualGL │ ──► │ TurboVNC │ ──► │ noVNC │ ──► │ Nginx │ ──► │ Browser  │
└─────────────┘     └──────────┘     └───────────┘     └──────────┘     └───────┘     └───────┘     └──────────┘
    OpenGL          Display :N        3D Redirect       VNC Server        WebSocket      Reverse       HTML5
    Rendering       xorg.conf         vglrun            Port 590N         Port 6080      Proxy         Client
```

### Component Breakdown

1. **GPU Layer**
   - Hardware: NVIDIA GPU
   - Access: `/dev/dri/card0`
   - Purpose: Provides hardware acceleration for 3D rendering
   - Container Access: Via NVIDIA runtime and device mounts
   - Requirements: NVIDIA driver 470+ and CUDA 11.4+
   - Environment Variables:
     ```bash
     NVIDIA_VISIBLE_DEVICES=all
     NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
     ```

2. **X Server Layer**
   - Software: Xorg
   - Configuration: `/etc/X11/xorg.conf`
   - Display: Unique numbers (`:1`, `:2`, etc.)
   - Driver: `modesetting`
   - Purpose: Handles display management and input
   - Features: Creates virtual framebuffer for display output
   - Key Files:
     ```
     /tmp/openuav/xorg/xorg.conf.N  # Display config
     /tmp/openuav/displays/N        # Display lock files
     ```

3. **VirtualGL Layer**
   - Purpose: OpenGL interception and redirection
   - Configuration: `VGL_DISPLAY=/dev/dri/card0`
   - Usage: `vglrun` command prefix
   - Function: Bridges GPU acceleration with virtual display
   - Features: Separates 3D (GPU) and 2D (virtual) rendering
   - Version: 3.1
   - Key Components:
     ```
     libvglfaker.so  # OpenGL interception
     vglserver_config # Server configuration
     vglconnect      # Client connection
     ```

4. **TurboVNC Layer**
   - Purpose: Display compression and remote access
   - Ports: 5901, 5902, etc. (unique per container)
   - Features:
     - Efficient display compression
     - Network optimization
     - Multi-user support
   - Integration: Works with both X server and VNC protocols
   - Version: 3.0.3
   - Configuration:
     ```bash
     /root/.vnc/xstartup    # VNC startup script
     /root/.vnc/config      # VNC configuration
     ```

5. **noVNC Layer**
   - Purpose: Web-based VNC client
   - Port: 6080
   - Features:
     - VNC to WebSocket conversion
     - HTML5-based display
     - No client installation needed
   - Access: Direct browser support
   - Components:
     ```
     websockify   # WebSocket proxy
     web/        # HTML5 client files
     core/       # JavaScript VNC client
     ```

6. **Nginx Proxy Layer**
   - Purpose: Web traffic routing
   - Features:
     - SSL/TLS termination
     - WebSocket support
     - Subdomain routing
   - URLs: `digital-twin-xxxxx.deepgis.org`
   - Configuration:
     ```nginx
     location / {
         proxy_pass http://container_ip:6080;
         proxy_http_version 1.1;
         proxy_set_header Upgrade $http_upgrade;
         proxy_set_header Connection "upgrade";
     }
     ```

### Example Flow

When running a 3D application like Gazebo:
```
┌──────────┐         ┌─────────┐         ┌────────┐
│  Gazebo  │ OpenGL  │VirtualGL│  GPU    │  X11   │
│  Client  │───────►│ Redirect│───────►│ Server │
└──────────┘         └─────────┘         └────────┘
                                            │
┌──────────┐         ┌─────────┐         ┌─┘
│  Web     │ HTML5   │  noVNC  │   VNC   │
│ Browser  │◄───────│  Proxy  │◄───────┘
└──────────┘         └─────────┘
```

1. Application makes OpenGL calls
2. VirtualGL intercepts and redirects to GPU
3. GPU performs 3D rendering
4. X server captures the rendered output
5. TurboVNC compresses the display
6. noVNC converts to WebSocket protocol
7. Nginx proxies to web browser

## Installation

### Prerequisites
- Ubuntu 20.04 or later
- NVIDIA GPU with 470+ drivers
- Docker 20.10+
- NVIDIA Container Toolkit

### Host Setup
1. Install NVIDIA drivers:
   ```bash
   ubuntu-drivers autoinstall
   ```

2. Install Docker:
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   ```

3. Install NVIDIA Container Toolkit:
   ```bash
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
   curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
   sudo apt-get update
   sudo apt-get install -y nvidia-docker2
   ```

### Building the Container
1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/openuav2.git
   cd openuav2
   ```

2. Build the image:
   ```bash
   docker build -t openuav:px4-sitl .
   ```

### Running Containers
1. Start a container:
   ```bash
   bash run_container.sh
   ```

2. Access via web browser:
   ```
   https://digital-twin-xxxxx.deepgis.org
   ```

## Troubleshooting

### Display Issues
1. Check X server logs:
   ```bash
   docker exec CONTAINER_ID cat /var/log/Xorg.1.log
   ```

2. Verify GPU access:
   ```bash
   docker exec CONTAINER_ID nvidia-smi
   ```

3. Test OpenGL:
   ```bash
   docker exec CONTAINER_ID vglrun glxinfo
   ```

### Network Issues
1. Check VNC server:
   ```bash
   docker exec CONTAINER_ID netstat -tulpn | grep 590
   ```

2. Verify noVNC:
   ```bash
   docker exec CONTAINER_ID netstat -tulpn | grep 6080
   ```

### Common Problems
1. Black screen: Usually X server or GPU driver issue
2. No 3D acceleration: Check VirtualGL configuration
3. Connection refused: Check port mappings and firewall

## Contributing
1. Fork the repository
2. Create your feature branch
3. Submit a pull request

## License
MIT License - See LICENSE file 
