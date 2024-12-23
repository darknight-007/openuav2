# Use CUDA 11.4.2 with Ubuntu 20.04 as base
FROM nvidia/cudagl:11.4.2-devel-ubuntu20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
ENV PULSE_SERVER=unix:/tmp/pulse/native
ENV DISPLAY=:1
ENV VGL_DISPLAY=egl

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git build-essential ca-certificates \
    gnupg2 apt-transport-https software-properties-common \
    python3-pip ipython3 vim less lsof net-tools htop \
    mesa-utils libgl1-mesa-glx libglu1-mesa xauth x11-utils xorg \
    libxv1 libxrender1 libxext6 libx11-6 \
    lubuntu-desktop terminator supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install TurboVNC and VirtualGL
RUN wget https://sourceforge.net/projects/turbovnc/files/3.0.3/turbovnc_3.0.3_amd64.deb && \
    wget https://sourceforge.net/projects/virtualgl/files/3.1/virtualgl_3.1_amd64.deb && \
    apt-get update && \
    apt-get install -y ./turbovnc_3.0.3_amd64.deb ./virtualgl_3.1_amd64.deb && \
    rm -f ./turbovnc_3.0.3_amd64.deb ./virtualgl_3.1_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

# Install ROS Foxy
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    ros-foxy-desktop \
    ros-foxy-gazebo-ros-pkgs \
    ros-foxy-gazebo-ros2-control \
    python3-rosdep \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/* \
    && rosdep init \
    && rosdep update

# Install noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Copy configuration files
COPY xorg.conf /etc/X11/xorg.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY xstartup.turbovnc /root/.vnc/xstartup
COPY terminator_config /root/.config/terminator/config
COPY self.pem /root/self.pem
COPY index.html /opt/noVNC/index.html

# Setup VNC and desktop configuration
RUN mkdir -p /root/.vnc /root/.config/terminator && \
    chmod +x /root/.vnc/xstartup && \
    echo "#!/bin/bash\nxsetroot -solid grey\n/usr/bin/lxsession -s Lubuntu &" > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Create desktop shortcuts
RUN mkdir -p /root/Desktop
COPY terminator.desktop chrome.desktop /root/Desktop/
RUN chmod +x /root/Desktop/*.desktop

# Configure VirtualGL
RUN vglserver_config -config +s +f -t

# Set ROS environment in bashrc
RUN echo "source /opt/ros/foxy/setup.bash" >> /root/.bashrc

# Expose ports
EXPOSE 6080 5901

# Set working directory
WORKDIR /root

# Start services using supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

