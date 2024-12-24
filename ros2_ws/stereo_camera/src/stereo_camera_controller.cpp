#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/camera_info.hpp>
#include <sensor_msgs/msg/image.hpp>

class StereoCameraController : public rclcpp::Node
{
public:
    StereoCameraController() : Node("stereo_camera_controller")
    {
        // Declare parameters
        this->declare_parameter("baseline", 0.290);
        this->declare_parameter("focal_length", 19.71);
        this->declare_parameter("field_of_view", 25.5);
        
        // Get parameters
        baseline_ = this->get_parameter("baseline").as_double();
        focal_length_ = this->get_parameter("focal_length").as_double();
        field_of_view_ = this->get_parameter("field_of_view").as_double();
        
        // Create publishers for camera info
        left_info_pub_ = this->create_publisher<sensor_msgs::msg::CameraInfo>(
            "stereo/left/camera_info", 10);
        right_info_pub_ = this->create_publisher<sensor_msgs::msg::CameraInfo>(
            "stereo/right/camera_info", 10);
            
        // Create timer to publish camera info
        timer_ = this->create_wall_timer(
            std::chrono::milliseconds(100),
            std::bind(&StereoCameraController::publishCameraInfo, this));
            
        RCLCPP_INFO(this->get_logger(), "Stereo camera controller initialized");
        RCLCPP_INFO(this->get_logger(), "Baseline: %f m", baseline_);
        RCLCPP_INFO(this->get_logger(), "Focal length: %f mm", focal_length_);
        RCLCPP_INFO(this->get_logger(), "Field of view: %f degrees", field_of_view_);
    }

private:
    void publishCameraInfo()
    {
        auto info_msg = sensor_msgs::msg::CameraInfo();
        info_msg.header.stamp = this->now();
        
        // Set camera matrix
        double fx = focal_length_ * 1000.0; // Convert to pixels
        double fy = fx;
        double cx = 640.0; // Image center x
        double cy = 360.0; // Image center y
        
        info_msg.k = {
            fx, 0.0, cx,
            0.0, fy, cy,
            0.0, 0.0, 1.0
        };
        
        // Set projection matrix
        info_msg.p = {
            fx, 0.0, cx, 0.0,
            0.0, fy, cy, 0.0,
            0.0, 0.0, 1.0, 0.0
        };
        
        // Set rectification matrix (identity for pinhole camera)
        info_msg.r = {
            1.0, 0.0, 0.0,
            0.0, 1.0, 0.0,
            0.0, 0.0, 1.0
        };
        
        // Set image size
        info_msg.width = 1280;
        info_msg.height = 720;
        
        // Publish left camera info
        info_msg.header.frame_id = "left_camera";
        left_info_pub_->publish(info_msg);
        
        // Publish right camera info
        info_msg.header.frame_id = "right_camera";
        info_msg.p[3] = -fx * baseline_; // Set right camera translation
        right_info_pub_->publish(info_msg);
    }

    double baseline_;
    double focal_length_;
    double field_of_view_;
    
    rclcpp::Publisher<sensor_msgs::msg::CameraInfo>::SharedPtr left_info_pub_;
    rclcpp::Publisher<sensor_msgs::msg::CameraInfo>::SharedPtr right_info_pub_;
    rclcpp::TimerBase::SharedPtr timer_;
}; 