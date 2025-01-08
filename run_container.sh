docker run --init \
    --runtime=nvidia \
    --name=digital-twin-133 \
    -it \
    -e DISPLAY=:1 \
    -v /tmp/.X11-unix/X1:/tmp/.X11-unix/X0:rw \
    -p 40001:40001 \
    openuav:ros-cuda-11.4.2-base-ubuntu20.04