from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node

def generate_launch_description():
    # Launch arguments for stereo camera configuration
    baseline = LaunchConfiguration('baseline')
    focal_length = LaunchConfiguration('focal_length')
    field_of_view = LaunchConfiguration('field_of_view')
    
    return LaunchDescription([
        # Declare launch arguments with default values
        DeclareLaunchArgument(
            'baseline',
            default_value='0.290',  # 290mm baseline
            description='Baseline distance between cameras in meters'
        ),
        DeclareLaunchArgument(
            'focal_length',
            default_value='19.71',  # 19.71mm focal length
            description='Focal length in mm'
        ),
        DeclareLaunchArgument(
            'field_of_view',
            default_value='25.5',  # 25.5 degrees FOV
            description='Field of view in degrees'
        ),
        
        # Spawn stereo camera URDF
        Node(
            package='gazebo_ros',
            executable='spawn_entity.py',
            name='spawn_stereo_camera',
            arguments=[
                '-entity', 'stereo_camera',
                '-file', '/home/simuser/ros2_ws/src/stereo_camera/urdf/stereo_camera.urdf.xacro',
                '-x', '0.0',
                '-y', '0.0',
                '-z', '0.3',  # Mount 30cm above the rover
                '-R', '0.0',
                '-P', '0.0',
                '-Y', '0.0'
            ],
            parameters=[{
                'baseline': baseline,
                'focal_length': focal_length,
                'field_of_view': field_of_view
            }]
        ),
        
        # Start stereo camera controller
        Node(
            package='stereo_camera',
            executable='stereo_camera_controller',
            name='stereo_camera_controller',
            parameters=[{
                'baseline': baseline,
                'focal_length': focal_length,
                'field_of_view': field_of_view
            }],
            output='screen'
        )
    ]) 