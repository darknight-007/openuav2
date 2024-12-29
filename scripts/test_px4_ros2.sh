#!/bin/bash

# Source ROS 2 and workspace
source /opt/ros/foxy/setup.bash
source /root/ros2_ws/install/setup.bash

# Test ROS 2 topics
echo "Checking available ROS 2 topics..."
ros2 topic list

# Test PX4 SITL status
echo -e "\nChecking PX4 SITL processes..."
ps aux | grep -E "px4|gzserver|micrortps"

# Test microRTPS bridge
echo -e "\nChecking microRTPS bridge topics..."
ros2 topic list | grep -E "fmu|vehicle"

# Test sensor data
echo -e "\nTrying to receive sensor data..."
timeout 5 ros2 topic echo /fmu/out/sensor_combined --once

echo -e "\nTest complete!" 