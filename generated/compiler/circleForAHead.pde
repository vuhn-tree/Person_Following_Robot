// draws a circle at the position of the head
void circleForAHead(int userId) {
    switch (trackOption) {
        case 0:
            kinect.getCoM(userId, jointPos);
            torsoOffset = 80;
            break;
        
        case 1:
            // get 3D position of a joint in the real world, and store it in jointPos.
            kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, jointPos);
            torsoOffset = 0;
            break;
            
        default:
            break;
    }
    
    // convert real world point to projective space. Converting real word
    // millimeters of jointPos to pixels coordinates stored in jointPos_Proj.
    kinect.convertRealWorldToProjective(jointPos, jointPos_Proj);
    float distanceScalar = (kinect.depthHeight()/jointPos_Proj.z);
    headVec.x = jointPos_Proj.x - kinect.depthWidth()/2;
    headVec.y = jointPos_Proj.y - kinect.depthHeight()/2;
    
    if (servoSeekY > 0 && servoSeekY < 180) {
        errorY = headVec.y;
        integralY = integralY + errorY;
        derivativeY = errorY - lastErrorY;
        turnY = kpY * errorY + kiY * integralY + kdY * derivativeY;
        powerServoY = round(tpY - turnY);
        if (errorY < 0 || errorX > 0) {
            servoSeekY = servoSeekY - powerServoY;
            
            arduino.analogWrite(servoYpin, servoSeekY);
        }
        lastErrorY = errorY;
    }
    
    errorX = headVec.x;
    integralX = integralX + errorX;
    derivativeX = errorX - lastErrorX;
    turnX = kpX * errorX + kiX * integralX + kdX * derivativeX;
    powerServoX = parseInt(tpX - turnX);
    if (errorX < 0 || errorX > 0) {
        servoSeekX = servoSeekX - powerServoX;
        arduino.analogWrite(servoXpin, servoSeekX);
    }
    lastErrorX = errorX;
    
    // a 200 pixel diameter head
    float headsize = 275;
   
    noFill();
    strokeWeight(2);
    // error X
    stroke(#ddc92a);
    ellipse(jointPos_Proj.x+headVec.x, jointPos_Proj.y-torsoOffset,
            distanceScalar*headsize, distanceScalar*headsize);
    
    // error Y
    stroke(#81a3d0);
    ellipse(jointPos_Proj.x, jointPos_Proj.y+headVec.y-torsoOffset,
            distanceScalar*headsize, distanceScalar*headsize);

    // zero error
    stroke(#cc2a36);
    ellipse(jointPos_Proj.x, jointPos_Proj.y-torsoOffset,
            distanceScalar*headsize, distanceScalar*headsize);
}
