#!/bin/bash

# Source ROS 2 and workspace
source /opt/ros/foxy/setup.bash
source /root/ros2_ws/install/setup.bash

# Set PX4 environment variables
export PX4_HOME_LAT=47.641468
export PX4_HOME_LON=-122.140165
export PX4_HOME_ALT=0.0

# Kill any existing processes
pkill -f px4
pkill -f gzserver
pkill -f gzclient
pkill -f micrortps_agent

# Start PX4 SITL with Gazebo
cd /root/src/PX4-Autopilot
HEADLESS=1 make px4_sitl_default gazebo &

# Wait for PX4 to start
sleep 10

# Start microRTPS bridge
micrortps_agent -t UDP &

# Start ROS 2 bridge
ros2 launch px4_ros_com sensor_combined_listener.launch.py &

# Keep script running
tail -f /dev/null 