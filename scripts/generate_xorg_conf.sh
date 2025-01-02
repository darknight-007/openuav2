#!/bin/bash

DISPLAY_NUM=$1

if [ -z "$DISPLAY_NUM" ]; then
    echo "Error: Display number not provided"
    echo "Usage: $0 <display_number>"
    exit 1
fi

# Create xorg config in temporary directory
XORG_CONFIG="/tmp/openuav/xorg/xorg.conf.${DISPLAY_NUM}"

cat > "${XORG_CONFIG}" << EOF
Section "ServerLayout"
    Identifier     "Layout${DISPLAY_NUM}"
    Screen      0  "Screen${DISPLAY_NUM}"
EndSection

Section "Device"
    Identifier  "Device${DISPLAY_NUM}"
    Driver      "modesetting"
    Option      "AccelMethod" "none"
EndSection

Section "Screen"
    Identifier "Screen${DISPLAY_NUM}"
    Device     "Device${DISPLAY_NUM}"
    DefaultDepth     24
    SubSection "Display"
        Depth     24
        Virtual   1920 1080
    EndSubSection
EndSection

Section "ServerFlags"
    Option "DontVTSwitch" "true"
    Option "AllowMouseOpenFail" "true"
    Option "PciForceNone" "true"
    Option "AutoAddDevices" "false"
EndSection

Section "Extensions"
    Option         "Composite" "Enable"
EndSection
EOF

echo "Generated X server configuration at ${XORG_CONFIG}" 