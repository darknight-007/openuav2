# Use CUDA 11.4.2 with Ubuntu 20.04 as base
FROM nvidia/cudagl:11.4.2-devel-ubuntu20.04

ARG SOURCEFORGE=https://sourceforge.net/projects
ARG TURBOVNC_VERSION=3.0.3
ARG VIRTUALGL_VERSION=3.1
ARG LIBJPEG_VERSION=3.0.0

# Install Ubuntu, VirtualGl, miniconda and novnc in one docker layer
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl wget apt-utils python3-pip vim less lsof net-tools git htop gedit gedit-plugins \
    libglib2.0-0 libxext6 libsm6 libxrender1 unzip zip psmisc xz-utils \
    python3-dev libsuitesparse-dev libeigen3-dev libxv1:i386 libglu1-mesa:i386 libsdl1.2-dev doxygen \
    gcc libc6-dev libglu1 libxv1 \
    lubuntu-desktop lubuntu-core lxsession xvfb terminator zenity mesa-utils \
    make cmake python3 x11-xkb-utils xauth xfonts-base xkb-data \
    libegl1-mesa libegl1-mesa-dev \
    xorg nvidia-utils-470 nvidia-settings && \
    rm -rf /var/lib/apt/lists/* && \
    cd /tmp && \
    curl -fsSL -O ${SOURCEFORGE}/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb \
        -O ${SOURCEFORGE}/libjpeg-turbo/files/${LIBJPEG_VERSION}/libjpeg-turbo-official_${LIBJPEG_VERSION}_amd64.deb \
        -O ${SOURCEFORGE}/virtualgl/files/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb && \
    dpkg -i *.deb && \
    rm -f /tmp/*.deb && \
    sed -i 's/$host:/unix:/g' /opt/TurboVNC/bin/vncserver && \
    cd /tmp && \
    curl -fsSL -O https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod u+x Miniconda3-latest-Linux-x86_64.sh && \
    ./Miniconda3-latest-Linux-x86_64.sh -b

# Install noVNC from package manager
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    python3-websockify novnc && \
    rm -rf /var/lib/apt/lists/*

ENV PATH ${PATH}:/opt/VirtualGL/bin:/root/miniconda3/bin

COPY xorg.conf /etc/X11/xorg.conf

# Install Chrome and VS Code
RUN mkdir -p /root/Desktop && \
    mkdir -p /root/.config/terminator && \
    mkdir -p /root/.vnc && \
    perl -pi -e 's/^Exec=terminator$/Exec=terminator -e "vglrun bash"/g' /usr/share/applications/terminator.desktop && \
    # Install Chrome
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    # Install VS Code
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y locales sudo ./google-chrome-stable_current_amd64.deb code --no-install-recommends && \
    rm -f ./google-chrome-stable_current_amd64.deb && \
    rm -f packages.microsoft.gpg && \
    # Setup locale
    sed -i '/force_color_prompt/s/^#//g' ~/.bashrc && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /tmp/*.deb && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    printf "%s\n" \
           "export LC_ALL=en_US.UTF-8" \
           "export LANG=en_US.UTF-8" \
           "export LANGUAGE=en_US.UTF-8" >> /root/.bashrc && \
    printf "%s\n" \
           "alias cp=\"cp -i\"" \
           "alias mv=\"mv -i\"" \
           "alias rm=\"rm -i\"" >> /root/.bash_aliases

# Create VS Code desktop shortcut
RUN echo "[Desktop Entry]\n\
Name=Visual Studio Code\n\
Comment=Code Editing. Redefined.\n\
GenericName=Text Editor\n\
Exec=/usr/bin/code\n\
Icon=/usr/share/pixmaps/com.visualstudio.code.png\n\
Type=Application\n\
StartupNotify=false\n\
Categories=TextEditor;Development;IDE;\n\
MimeType=text/plain;" > /root/Desktop/code.desktop && \
chmod +x /root/Desktop/code.desktop

EXPOSE 6080 5901
ENV DISPLAY=:1

COPY terminator.desktop /root/Desktop/
COPY ./terminator_config /root/.config/terminator/config
COPY ./self.pem /root/self.pem
COPY ./xstartup.turbovnc /root/.vnc/xstartup
COPY ./chrome.desktop /root/Desktop/
COPY start_desktop.sh /usr/local/bin/

RUN chmod +x /root/.vnc/xstartup && \
    chmod +x /usr/local/bin/start_desktop.sh

ENTRYPOINT ["/usr/local/bin/start_desktop.sh"]