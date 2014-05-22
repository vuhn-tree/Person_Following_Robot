// Keyboard event
void keyPressed() {
    switch(key) {
        case ' ':
            foundHead = false;
            arduino.analogWrite(servoXpin, servoInitX);
//            servoSpeed(servoInitX, 2);
            arduino.analogWrite(servoYpin, servoInitY);
            servoSeekX = servoInitX;
            servoSeekY = servoInitY;
            kinect.stopPoseDetection(person);
            kinect.startPoseDetection("Psi", 1);
            initVar();
            break;
        case 'c':
            satCalib = true;
            break;
        case 's':
            satSearch = true;
            break;
    }
    
    switch(keyCode)
    {
        case LEFT:
            trackOption--;
            break;
        case RIGHT:
            trackOption++;
            break;
        case ENTER:
            foundHead = true;
            break;
        case UP:
            camType++;
            break;
        case DOWN:
            camType--;
            break;
    }
}
