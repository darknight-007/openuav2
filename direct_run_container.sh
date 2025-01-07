docker run --init \
    --privileged \
    --network dreamslab \
    --runtime=nvidia \
    --gpus all \
    --name=digital-twin-test123 \
    -it \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -e VGL_DISPLAY=:0 \
    -e DISPLAY=:0 \
    -p 40001:40001 \
    openuav:px4-sitl


