# OpenUAV2 Container Architecture

This repository contains the containerized environment for OpenUAV simulations with GPU acceleration and web-based access.

## Container Components

The OpenUAV container consists of two main component groups:

### Simulation Components
- **Gazebo**: 3D robotics simulator
- **Unity**: 3D visualization engine
- **ROS**: Robot Operating System framework
- **PX4**: UAV autopilot software
- **QGroundControl**: Ground control station

### User-Interactive Components
- **NoVNC**: Web-based VNC client (Port 40001)
- **TurboVNC**: High-performance VNC server
- **SSH/SSHFS**: Secure shell access and filesystem mounting (Port 22)

```
┌─────────────────────────────────────────────────────────┐
│                OpenUAV Container                        │
│  ┌─────────────────────────────────────────────┐       │
│  │           Simulation Components              │       │
│  │   ┌────────┐  ┌───────┐  ┌─────┐  ┌────┐   │       │
│  │   │ Gazebo │  │ Unity │  │ ROS │  │PX4 │   │       │
│  │   └────────┘  └───────┘  └─────┘  └────┘   │       │
│  │          ┌─────────────────┐                │       │
│  │          │ QGroundControl  │                │       │
│  │          └─────────────────┘                │       │
│  └─────────────────────────────────────────────┘       │
│                                                        │
│  ┌─────────────┐    ┌──────────┐    ┌──────────┐      │
│  │   NoVNC     │    │ TurboVNC │    │SSH/SSHFS │      │
│  │  (40001)    │    │          │    │  (22)    │      │
│  └─────────────┘    └──────────┘    └──────────┘      │
└─────────────────────────────────────────────────────────┘
```

## Network Architecture

The OpenUAV platform uses Nginx as a reverse proxy to handle both HTTP and SSH connections:

### Components
1. **Nginx Proxy**
   - HTTP proxy module: Handles web interface access
   - Stream module: Manages SSH connections
   - Domain format: cpsvo-<uniqueID>.openuav.us

2. **DNS Resolver**
   - Resolves container-specific URLs to Docker network IPs
   - Handles dynamic container addressing

3. **Container Instances**
   - Multiple containers run in parallel
   - Each container has:
     - Web interface (NoVNC)
     - SSH access
     - Unity + Gazebo simulation environment

```
┌─────────────────────────────────────────────────────────┐
│                     Nginx Proxy                         │
│  ┌───────────────────┐      ┌────────────────────┐     │
│  │   HTTP Module     │      │    Stream Module   │     │
│  └─────────┬─────────┘      └──────────┬─────────┘     │
└────────────┼──────────────────────────┬┼───────────────┘
             │                          ││
┌────────────┼──────────────────────────┼┼───────────────┐
│            ▼                          ▼▼               │
│  ┌─────────────────┐      ┌─────────────────┐         │
│  │  Container 1    │      │  Container 2    │   ...   │
│  │digital-twin-1   │      │digital-twin-2   │         │
│  └─────────────────┘      └─────────────────┘         │
│                Docker Network                          │
└─────────────────────────────────────────────────────────┘
```

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
   docker exec CONTAINER_ID netstat -tulpn | grep 40001
   ```

### Common Problems
1. Black screen: Usually X server or GPU driver issue
2. No 3D acceleration: Check VirtualGL configuration
3. Connection refused: Check port mappings and firewall

### Notes: 
sudo pkill -f "Xorg :1"
sudo Xorg :0 -isolateDevice PCI:82:0:0 -config /etc/X11/xorg.conf -noreset vt1
-e DISPLAY=:1     # For TurboVNC's 2D operations
-e VGL_DISPLAY=:0 # For GPU-accelerated 3D rendering

## Contributing
1. Fork the repository
2. Create your feature branch
3. Submit a pull request

## License
MIT License - See LICENSE file 
