
PVector jointPos = new PVector();
PVector jointPos_Proj = new PVector();
PVector error = new PVector();

float kpX, kiX, kdX, turnX, integralX, lastErrorX, derivativeX;
float kpY, kiY, kdY, turnY, integralY, lastErrorY, derivativeY;

int servoInitX = 90;
int servoInitY = 50;
int servoSeekX = servoInitX;
int servoSeekY = servoInitY;

float kpS = 0.3, turnS, kiS = 0.001, kdS=0.1, integralS, derivativeS, lastErrorS;

int offsetY = -45;
int leftMotor, rightMotor;
float followDist = 2000;

void centerTorso() {
    float distanceScalar = (kinect.depthHeight()/jointPos_Proj.z);
    float headsize = 275;
    error.z = jointPos_Proj.z - followDist;

    error.y = jointPos_Proj.y - kinect.depthHeight()/2 + offsetY;
    integralY = integralY + error.y;
    derivativeY = error.y - lastErrorY;
    lastErrorY = error.y;
    turnY = kpY * error.y + kiY * integralY + kdY * derivativeY;

    error.x = jointPos_Proj.x - kinect.depthWidth()/2;
    integralX = integralX + error.x;
    derivativeX = error.x - lastErrorX;
    lastErrorX = error.x;
    turnX = kpX * error.x + kiX * integralX + kdX * derivativeX;

    servoSeekX = servoSeekX - parseInt(turnX);
    servoSeekY = servoSeekY - parseInt(turnY);
    updateServo(servoSeekX, servoSeekY);

    if (moveMotors == true && !Float.isNaN(turnX)) {
        if(error.z > 300) {
            error.z = 300;
        }
        int moveDist = parseInt(error.z*0.7);
        int segwayError = servoInitX - servoSeekX;

        leftMotor = -parseInt(segwayError*1.4)+moveDist;
        rightMotor = parseInt(segwayError*1.4)+moveDist;

        move(leftMotor, rightMotor);
    }

    noFill();
    strokeWeight(2);
    // error X
    stroke(#ddc92a);
    line(jointPos_Proj.x+error.x, 0, jointPos_Proj.x+error.x, 480);

    // error Y
    stroke(#81a3d0);
    line(0, jointPos_Proj.y+error.y+offsetY, 640, jointPos_Proj.y+error.y+offsetY);

    // zero error
    stroke(#cc2a36);
    ellipse(jointPos_Proj.x, jointPos_Proj.y+offsetY, 
    distanceScalar*headsize, distanceScalar*headsize);
}

void updateServo(int servoXPOS, int servoYPOS) { 

    arduino.write(servoXPOS+"x");
    arduino.write(servoYPOS+"y");
}

public void move(int left, int right) {
    if (left > 500)
        left = 500;
    if (left < -500)
        left = -500;

    if (right > 500)
        right = 500;
    if (right < -500)
        right = -500;

    // Full Mode
    icreate.write(128);
    icreate.write(131);

    // Motor Operator
    icreate.write(145);

    // 2's complement right velocity 
    if (right < 0) {
        right = ~(-right) + 1;
    }
    int highByte_R = (right >> 8) & 0xFF;
    int lowByte_R = right & 0xFF;
    icreate.write(highByte_R);
    icreate.write(lowByte_R);

    // 2's complement left velocity
    if (left < 0) {
        left = ~(-left) + 1;
    }
    int highByte_L = (left >> 8) & 0xFF;
    int lowByte_L = left & 0xFF;
    icreate.write(highByte_L);
    icreate.write(lowByte_L);
}

