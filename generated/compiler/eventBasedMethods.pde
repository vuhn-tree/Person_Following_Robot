// Event-based Methods

// when a person ('user') enters the field of view
void onNewUser(int userId)
{
    println("New User Detected - userId: " + userId);
    person = userId;
//    arduino.analogWrite(servoXpin, servoSeekX);
//    arduino.analogWrite(servoYpin, servoSeekY);
    // start pose detection
    if(trackOption == 1) {
        kinect.startPoseDetection("Psi", userId);
    }
}

// when a person ('user') leaves the field of view
void onLostUser(int userId)
{
    initVar();
    println("User Lost - userId: " + userId);
}

// when a user begins a pose
void onStartPose(String pose, int userId)
{
    println("HIStart of Pose Detected  - userId: " + userId +
            ", pose: " + pose);
    person = userId;
    // stop pose detection
    kinect.stopPoseDetection(userId);
    
    // start attempting to calibrate the skeleton
    kinect.requestCalibrationSkeleton(userId, true);
}

// when calibration begins
void onStartCalibration(int userId)
{
    println("Beginning Calibration - userId: " + userId);
}

// when calibaration ends - successfully or unsucessfully
void onEndCalibration(int userId, boolean successfull)
{
    println("Calibration of userId: " + userId +
            ", successfull: " + successfull);
    
    if (successfull)
    {
        println("  User calibrated !!!");
        
        // begin skeleton tracking
        kinect.startTrackingSkeleton(userId);
        
    }
    else
    {
        println("  Failed to calibrate user !!!");
        
        // Start pose detection
        kinect.startPoseDetection("Psi", userId);
    }
}
