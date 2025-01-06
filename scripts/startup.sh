#!/bin/bash

# Enable error handling and logging
set -e
exec 1> >(tee -a $HOME/.openuav/logs/openuav.log) 2>&1
echo "[$(date)] Starting OpenUAV container..."

# Function to check GPU availability
check_gpu() {
    if ! nvidia-smi > /dev/null 2>&1; then
        echo "[$(date)] ERROR: NVIDIA GPU not detected"
        return 1
    fi
    echo "[$(date)] GPU check passed"
    return 0
}

# Function to clean up processes
cleanup_processes() {
    echo "[$(date)] Cleaning up existing processes..."
    pkill -f vncserver || true
    pkill -f Xvnc || true
    pkill -f Xorg || true
    pkill -f px4 || true
    pkill -f gzserver || true
    pkill -f gzclient || true
    
    # Wait for processes to fully terminate
    sleep 2
}

# Function to setup X11 environment
setup_x11() {
    echo "[$(date)] Setting up X11 environment..."
    
    # Create and setup OpenUAV directories
    mkdir -p $HOME/.openuav/{x11,displays,dbus,logs}
    chmod 700 $HOME/.openuav
    chmod 700 $HOME/.openuav/{x11,displays,dbus,logs}
    
    # Clean up X11 sockets but preserve the mount point
    rm -f $HOME/.openuav/x11/.X* || true
    rm -f $HOME/.openuav/x11/.x* || true
    
    # Set proper permissions for X11 directory
    chmod 1777 $HOME/.openuav/x11
    
    # Create fake EDID for X server
    mkdir -p /etc/X11
    dd if=/dev/zero of=/etc/X11/edid.bin bs=1 count=128 2>/dev/null
    
    # Set display environment
    export DISPLAY=:1
}

# Function to start X server
start_xserver() {
    echo "[$(date)] Starting X server..."
    Xorg :1 -config /etc/X11/xorg.conf -sharevts -novtswitch -nolisten tcp -noreset &
    XPID=$!
    sleep 2
    
    # Check if X server is running
    if ! ps -p $XPID > /dev/null; then
        echo "[$(date)] ERROR: X server failed to start"
        return 1
    fi
    
    # Test X server
    DISPLAY=:1 xdpyinfo > /dev/null 2>&1 || {
        echo "[$(date)] ERROR: X server not responding"
        return 1
    }
    
    echo "[$(date)] X server started successfully"
    return 0
}

# Function to start VNC server
start_vnc() {
    echo "[$(date)] Starting VNC server..."
    mkdir -p $HOME/.vnc
    /opt/TurboVNC/bin/vncserver :1 -geometry 1920x1080 -depth 24 -noxstartup -rfbport 5901
    sleep 2
    
    # Verify VNC server is running
    if ! pgrep -f vncserver > /dev/null; then
        echo "[$(date)] ERROR: VNC server failed to start"
        return 1
    fi
    
    echo "[$(date)] VNC server started successfully"
    return 0
}

# Function to start noVNC
start_novnc() {
    echo "[$(date)] Starting noVNC..."
    /opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 6080 &
    sleep 2
    
    # Verify noVNC is running
    if ! pgrep -f novnc_proxy > /dev/null; then
        echo "[$(date)] ERROR: noVNC failed to start"
        return 1
    fi
    
    echo "[$(date)] noVNC started successfully"
    return 0
}

# Main execution
main() {
    # Check GPU first
    check_gpu || exit 1
    
    # Setup environment
    cleanup_processes
    setup_x11
    
    # Start services
    start_xserver || exit 1
    start_vnc || exit 1
    start_novnc || exit 1
    
    echo "[$(date)] All services started successfully"
    
    # Monitor critical processes
    while true; do
        if ! pgrep -f Xorg > /dev/null; then
            echo "[$(date)] ERROR: X server died, attempting restart..."
            start_xserver || {
                echo "[$(date)] FATAL: Could not restart X server"
                exit 1
            }
        fi
        
        if ! pgrep -f vncserver > /dev/null; then
            echo "[$(date)] WARNING: VNC server died, restarting..."
            start_vnc
        fi
        
        if ! pgrep -f novnc_proxy > /dev/null; then
            echo "[$(date)] WARNING: noVNC died, restarting..."
            start_novnc
        fi
        
        sleep 5
    done
}

# Run main function
main 