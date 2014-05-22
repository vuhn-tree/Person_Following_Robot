
void keyPressed() {
    switch(key) {
    case ' ':
        updateServo(servoInitX, servoInitY);
        servoSeekX = servoInitX;
        servoSeekY = servoInitY;
        initVar(); 
        break;
    }

    switch(keyCode) {
    case LEFT:
        kinect.resetUserCoordsys();
        //        servoSeekX++;
        break;
    case RIGHT:
        //        servoSeekX--;
        break;
    case UP:
        
        moveMotors = true;
        //        servoSeekY++;
        break;
    case DOWN:
        moveMotors = false;
        //        servoSeekY--;
        break;
    }
}

