#!/bin/bash

source /opt/ros/foxy/setup.bash

cd /root/src/PX4-Autopilot

# Set environment variables for Gazebo
export GAZEBO_PLUGIN_PATH=$GAZEBO_PLUGIN_PATH:/root/src/PX4-Autopilot/build/px4_sitl_default/build_gazebo
export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:/root/src/PX4-Autopilot/Tools/sitl_gazebo/models
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/src/PX4-Autopilot/build/px4_sitl_default/build_gazebo

# Set display for GUI applications
export DISPLAY=:1

# Start PX4 SITL with Gazebo
HEADLESS=0 make px4_sitl_default gazebo 