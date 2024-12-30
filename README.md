# OpenUAV with PX4 SITL and ROS 2

This repository contains a Docker-based development environment for OpenUAV, integrating PX4 SITL with ROS 2 Foxy and GPU acceleration support.

## Features

- ROS 2 Foxy with Gazebo integration
- PX4 SITL (Software In The Loop) simulation
- NVIDIA GPU acceleration support
- Remote desktop access via VNC/noVNC
- TurboVNC and VirtualGL for hardware-accelerated 3D graphics
- GNOME desktop environment

## Prerequisites

- Ubuntu 20.04 or later
- NVIDIA GPU with appropriate drivers installed
- Docker with NVIDIA container toolkit
- Docker Compose (optional)

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/darknight-007/openuav2
cd openuav2
```

2. Build the Docker image:
```bash
docker build -t openuav:px4-sitl -f Dockerfile.px4 .
```

3. Run the container:
```bash
docker run -d --name gpu-vnc-test \
    --privileged \
    --gpus '"device=1"' \
    -p 6080:6080 \
    -p 5901:5901 \
    -e NVIDIA_VISIBLE_DEVICES=1 \
    -e NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute \
    --runtime=nvidia \
    openuav:px4-sitl
```

4. Access the desktop environment:
   - Via web browser: `http://localhost:6080/vnc.html`
   - Via VNC client: `localhost:5901`

## Container Details

### Ports
- 5901: TurboVNC server
- 6080: noVNC web interface

### Environment Variables
- `DISPLAY=:1`: X display number
- `VGL_DISPLAY=egl`: VirtualGL display type
- `NVIDIA_VISIBLE_DEVICES=1`: GPU device ID
- `NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute`: Required GPU capabilities

### Installed Software
- ROS 2 Foxy
- Gazebo 11
- PX4 Autopilot
- TurboVNC 3.0.3
- VirtualGL 3.1
- NVIDIA CUDA 11.4.2
- Python 3 with common development tools

## Development Environment

The container provides a full development environment with:
- GNOME desktop environment
- Terminator terminal emulator
- Common development tools (git, vim, etc.)
- GPU-accelerated 3D graphics support

## Building from Source

To build the image from source:

1. Ensure you have the NVIDIA Container Toolkit installed:
```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
```

2. Build the Docker image:
```bash
docker build -t openuav:px4-sitl -f Dockerfile.px4 .
```

## Troubleshooting

1. If the VNC connection fails:
   - Check if the container is running: `docker ps`
   - View container logs: `docker logs gpu-vnc-test`
   - Ensure ports 5901 and 6080 are not in use

2. If GPU acceleration is not working:
   - Verify NVIDIA drivers are installed: `nvidia-smi`
   - Check NVIDIA Container Toolkit installation
   - Ensure the container has GPU access

3. For desktop environment issues:
   - Check VNC server logs: `docker exec gpu-vnc-test cat /root/.vnc/*.log`
   - Verify X server is running: `docker exec gpu-vnc-test ps aux | grep Xvnc`

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- PX4 Development Team
- ROS 2 Community
- NVIDIA Container Toolkit Team
- TurboVNC and VirtualGL Projects 
