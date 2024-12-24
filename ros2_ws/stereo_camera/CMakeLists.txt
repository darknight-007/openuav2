cmake_minimum_required(VERSION 3.8)
project(stereo_camera)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(gazebo_ros REQUIRED)

# Add the stereo camera controller executable
add_executable(stereo_camera_controller src/stereo_camera_controller.cpp)
ament_target_dependencies(stereo_camera_controller
  rclcpp
  sensor_msgs
  gazebo_ros
)

# Install executables
install(TARGETS
  stereo_camera_controller
  DESTINATION lib/${PROJECT_NAME}
)

# Install launch files
install(DIRECTORY
  launch
  DESTINATION share/${PROJECT_NAME}
)

# Install URDF files
install(DIRECTORY
  urdf
  DESTINATION share/${PROJECT_NAME}
)

ament_package() 