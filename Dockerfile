# Use CUDA 11.4.2 with Ubuntu 20.04 as base
FROM nvidia/cudagl:11.4.2-devel-ubuntu20.04

# Arguments for additional software sources
ARG SOURCEFORGE=https://sourceforge.net/projects
ARG TURBOVNC_VERSION=3.0.3
ARG VIRTUALGL_VERSION=3.1
ARG LIBJPEG_VERSION=3.0.0

# Set noninteractive frontend to prevent prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Add universe and multiverse repositories for additional packages
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    add-apt-repository multiverse && \
    apt-get update && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    rm -rf /var/lib/apt/lists/*

# Install Ubuntu, VirtualGL, Miniconda, and noVNC in one Docker layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget apt-utils python3-pip vim less lsof net-tools git htop gedit gedit-plugins \
    libglib2.0-0 libxext6 libsm6 libxrender1 unzip zip psmisc xz-utils \
    python3-dev libsuitesparse-dev libeigen3-dev libxv1:i386 libglu1-mesa:i386 libsdl1.2-dev doxygen \
    gcc libc6-dev libglu1 libxv1 \
    lubuntu-desktop lxsession openbox pcmanfm lxde-core lxterminal \
    xvfb terminator zenity mesa-utils \
    make cmake python3 x11-xkb-utils xauth xfonts-base xkb-data \
    libegl1-mesa libegl1-mesa-dev \
    xorg nvidia-utils-470 nvidia-settings && \
    rm -rf /var/lib/apt/lists/* && \
    pip3 install numpy setuptools wheel && \
    cd /opt && \
    git clone https://github.com/novnc/noVNC.git && \
    cd noVNC && \
    git checkout v1.4.0 && \
    ln -s vnc.html index.html && \
    cd .. && \
    git clone https://github.com/novnc/websockify.git && \
    cd websockify && \
    git checkout v0.11.0 && \
    python3 setup.py install && \
    which websockify

# Download and install TurboVNC, VirtualGL, and libjpeg-turbo
RUN cd /tmp && \
    curl -fsSL -O ${SOURCEFORGE}/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb \
               -O ${SOURCEFORGE}/libjpeg-turbo/files/${LIBJPEG_VERSION}/libjpeg-turbo-official_${LIBJPEG_VERSION}_amd64.deb \
               -O ${SOURCEFORGE}/virtualgl/files/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb && \
    dpkg -i *.deb && \
    rm -f /tmp/*.deb && \
    sed -i 's/$host:/unix:/g' /opt/TurboVNC/bin/vncserver

# Install Miniconda
RUN cd /tmp && \
    curl -fsSL -O https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod u+x Miniconda3-latest-Linux-x86_64.sh && \
    ./Miniconda3-latest-Linux-x86_64.sh -b && \
    rm -f Miniconda3-latest-Linux-x86_64.sh

# Update PATH to include noVNC
ENV PATH=/opt/VirtualGL/bin:/root/miniconda3/bin:/opt/noVNC/utils:${PATH}

# Copy configuration files and scripts
COPY xorg.conf /etc/X11/xorg.conf
COPY terminator.desktop /root/Desktop/
COPY ./terminator_config /root/.config/terminator/config
COPY ./self.pem /root/self.pem
COPY ./xstartup.turbovnc /root/.vnc/xstartup
COPY ./chrome.desktop /root/Desktop/
COPY start_desktop.sh /usr/local/bin/

# Make necessary scripts executable
RUN chmod +x /root/.vnc/xstartup && \
    chmod +x /usr/local/bin/start_desktop.sh

# Install Chrome and Visual Studio Code
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && \
    apt-get install -y ./google-chrome-stable_current_amd64.deb code --no-install-recommends && \
    rm -f ./google-chrome-stable_current_amd64.deb && \
    rm -f packages.microsoft.gpg && \
    rm -rf /var/lib/apt/lists/*

# Configure locale
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    printf "%s\n" \
           "export LC_ALL=en_US.UTF-8" \
           "export LANG=en_US.UTF-8" \
           "export LANGUAGE=en_US.UTF-8" >> /root/.bashrc && \
    printf "%s\n" \
           "alias cp=\"cp -i\"" \
           "alias mv=\"mv -i\"" \
           "alias rm=\"rm -i\"" >> /root/.bash_aliases && \
    rm -rf /var/lib/apt/lists/*

# Expose necessary ports
EXPOSE 6080 5901

# Set default display
ENV DISPLAY=:1

# Start the desktop environment
CMD ["/usr/local/bin/start_desktop.sh"]
