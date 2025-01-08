docker run --init \
    --network dreamslab \
    --gpus all \
    --name=digital-twin-test123 \
    -it \
    -e NVIDIA_DRIVER_CAPABILITIES=graphics,display,video,utility \
    -e VGL_DISPLAY=:0 \
    -e DISPLAY=:1 \
    -v /tmp/.X11-unix/X1:/tmp/.X11-unix/X1:rw \
    -p 40001:40001 \
    openuav:px4-sitl


