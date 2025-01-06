docker run --init --network dreamslab --runtime=nvidia --name=digital-twin-test123 -it -e DISPLAY=:1 -v /tmp/.X11-unix/X0:/tmp/.X11-unix/X0:rw -p 40001:40001 openuav:px4-sitl


