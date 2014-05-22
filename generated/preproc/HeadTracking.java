import processing.core.*; 
import processing.xml.*; 

import processing.serial.*; 
import SimpleOpenNI.*; 
import controlP5.*; 
import gab.opencv.*; 
import java.awt.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class HeadTracking extends PApplet {

 






ControlP5 cp5;
Chart pidGraph, satGraph;
Serial arduino;
SimpleOpenNI kinect;
OpenCV opencv;

int kWidth;
int kHeight;

int person = 1;
PImage imgRGB;
int frameSkip = 1;

boolean trackTorso = false;
boolean trackHueSat = false;
boolean openCV = false;
boolean sweepLeft = true; 
boolean sweep = true;

PImage cv;

Rectangle[] faces;

PVector handPosition;

public void setup() {

    println(Serial.list());
    arduino = new Serial(this, Serial.list()[4], 115200);

    PFont font = createFont("arial", 16);
    textFont(font);

    kinect = new SimpleOpenNI(this);
    kinect.setMirror(true);
    kinect.enableDepth();
    kinect.enableRGB();
    kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
    kWidth = kinect.rgbWidth();
    kHeight = kinect.rgbHeight();

    kinect.loadCalibrationDataSkeleton(person, "calibration.skel");

    smooth();
    size(kWidth, kHeight+graphSize);

    cp5 = new ControlP5(this);

    pidGraph = cp5.addChart("PID Graph")
        .setPosition(0, 480)
            .setSize(320, 300)
                .setRange(-150, 150)
                    .setView(Chart.LINE)
                        ;
    pidGraph.getColor().setBackground(color(255, 100));    
    pidGraph.addDataSet("PosX");
    pidGraph.setColors("PosX", 0xffddc92a);
    pidGraph.setData("PosX", new float[320]);
    pidGraph.addDataSet("PosY");
    pidGraph.setColors("PosY", 0xff81a3d0);
    pidGraph.setData("PosY", new float[320]);

    satGraph = cp5.addChart("Sat Graph")
        .setPosition(320, 480)
            .setSize(320, 300)
                .setRange(0, 300)
                    .setView(Chart.BAR)
                        ;    
    satGraph.getColor().setBackground(color(255, 100));         
    satGraph.addDataSet("sat");
    satGraph.setColors("sat", color(255), color(0, 255, 0));
    satGraph.setData("sat", new float[320]);
    satGraph.addDataSet("cal");
    satGraph.setColors("cal", color(0, 0, 255));
    satGraph.setData("cal", new float[320]);

    cp5.addTextfield("KP X")
        .setPosition(360, 520)
            .setSize(70, 25)
                .setFont(font)
                    .setAutoClear(false)
                        .setColor(color(255, 0, 0))
                            .setText("0.0350")
                                ;

    cp5.addTextfield("KI X")
        .setPosition(440, 520)
            .setSize(70, 25)
                .setFont(font)
                    .setAutoClear(false)
                        .setColor(color(255, 0, 0))
                            .setText("0.0010")
                                ;

    cp5.addTextfield("KD X")
        .setPosition(520, 520)
            .setSize(70, 25)
                .setFont(font)
                    .setAutoClear(false)
                        .setColor(color(255, 0, 0))
                            .setText("0.1000")
                                ;

    cp5.addTextfield("KP Y")
        .setPosition(360, 570)
            .setSize(70, 25)
                .setFont(font)
                    .setAutoClear(false)
                        .setColor(color(255, 0, 0))
                            .setText("0.0090")
                                ;

    cp5.addTextfield("KI Y")
        .setPosition(440, 570)
            .setSize(70, 25)
                .setFont(font)
                    .setAutoClear(false)
                        .setColor(color(255, 0, 0))
                            .setText("0.0005")
                                ;

    cp5.addTextfield("KD Y")
        .setPosition(520, 570)
            .setSize(70, 25)
                .setFont(font)
                    .setAutoClear(false)
                        .setColor(color(255, 0, 0))
                            .setText("0.0040")
                                ;

    kpX = parseFloat(cp5.get(Textfield.class, "KP X").getText());
    kiX = parseFloat(cp5.get(Textfield.class, "KI X").getText());
    kdX = parseFloat(cp5.get(Textfield.class, "KD X").getText());

    kpY = parseFloat(cp5.get(Textfield.class, "KP Y").getText());
    kiY = parseFloat(cp5.get(Textfield.class, "KI Y").getText());
    kdY = parseFloat(cp5.get(Textfield.class, "KD Y").getText());

    cp5.addButton("saveCalibration")
        .setValue(1)
            .setPosition(360, 700)
                .setSize(75, 19)
                    .setCaptionLabel("SAVE CAL")
                        ;

    cp5.addToggle("trackTorso")
        .setPosition(360, 625)
            .setSize(75, 20)
                .setCaptionLabel("TRACK TORSO")
                    .setMode(ControlP5.SWITCH)
                        ;

    cp5.addToggle("trackHueSat")
        .setPosition(440, 625)
            .setSize(75, 20)
                .setCaptionLabel("TRACK HUE-SAT")
                    .setMode(ControlP5.SWITCH)
                        ;

    cp5.addToggle("openCV")
        .setPosition(520, 625)
            .setSize(75, 20)
                .setCaptionLabel("OPEN CV")
                    .setMode(ControlP5.SWITCH)
                        ;

    opencv = new OpenCV(this, 640/2, 480/2);
    opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE); 
    cv = new PImage(320, 240);
    
    kinect.enableGesture();
    kinect.enableHands();
    kinect.addGesture("RaiseHand");
    handPosition = new PVector();

    initVar();
}

public void draw() {

    if (frameCount%frameSkip==0) {

        kinect.update();

        fill(0);
        stroke(0);
        strokeWeight(0);
        rect(0, kHeight, kWidth, graphSize);

        //        switch (trackOption) {
        //        case 0:
        //            image(kinect.rgbImage(), 0, 0);
        //            if (Float.isNaN(turnX)) {
        //                initVar();
        //            }
        //            if (foundHead == true) {
        //                circleForAHead(person);
        //            }
        //            break;
        //
        //        case 3:
        //            kinect.enableScene();
        //            image(kinect.sceneImage(), 0, 0);
        //            break;
        //        default:
        //            break;
        //        }

        if (trackTorso==true) {
            image(kinect.rgbImage(), 0, 0);
            if (kinect.isTrackingSkeleton(person)) {
                float confidence = kinect.getJointPositionSkeleton(person, SimpleOpenNI.SKEL_TORSO, jointPos);
                kinect.convertRealWorldToProjective(jointPos, jointPos_Proj);
                circleForAHead(person);
            } 
            //            else if (kinect.loadCalibrationDataSkeleton(person, "calibration.skel")) {
            else {
                kinect.startTrackingSkeleton(person);
            }
            

//            if (frameCount%1==0 && sweep==true) {
//                if (sweepLeft==true) {
////                    println("Sweeping left");
//                    updateServo(servoSeekX++, servoSeekY);
//                    if (servoSeekX==140) {
//                        sweepLeft = false;
//                    }
//                } 
//                else {
////                    println("Sweeping right");
//                    updateServo(servoSeekX--, servoSeekY);
//                    if (servoSeekX==40) {
//                        sweepLeft = true;
//                    }
//                }
//                
//                if (openCV == true) {
//                    cv.copy(kinect.rgbImage(), 0, 0, 640, 480, 0, 0, 320, 240);
//                    opencv.loadImage(cv);
//                    noFill();
//                    stroke(0, 255, 0);
//                    strokeWeight(3);
//                    faces = opencv.detect();
//                    for (int i = 0; i < faces.length; i++) {
//                        //                println(faces[i].x*2 + "," + faces[i].y*2);
//                        rect(faces[i].x*2, faces[i].y*2, faces[i].width*2, faces[i].height*2);
//                        if (faces[i].x*2>300 && faces[i].width*2<340) {
//                            sweep = false;
//                        }
//                    }
//                }
//                
//            }
            graphPID();
        }

        if (trackHueSat == true) {
            imgRGB = kinect.rgbImage();
            satSearch();
        }



        fill(0xff8cb990);
        text("Head Tracking Kinect Robot by Richard Vu"+
            "\nFrame Rate: "+frameRate+
            "\nFrame Skip: "+frameSkip+
            "\nservoX: " + servoSeekX + 
            "  servoY: " + servoSeekY, 15, kHeight + 20);
    }
}

public void controlEvent(ControlEvent theEvent) {

    if (theEvent.isAssignableFrom(Textfield.class)) {
        //        println("controlEvent: accessing a string from controller '"
        //            +theEvent.getName()+"': "
        //            +theEvent.getStringValue()
        //            );

        kpX = parseFloat(cp5.get(Textfield.class, "KP X").getText());
        kiX = parseFloat(cp5.get(Textfield.class, "KI X").getText());
        kdX = parseFloat(cp5.get(Textfield.class, "KD X").getText());

        kpY = parseFloat(cp5.get(Textfield.class, "KP Y").getText());
        kiY = parseFloat(cp5.get(Textfield.class, "KI Y").getText());
        kdY = parseFloat(cp5.get(Textfield.class, "KD Y").getText());
    }
}

public void saveCalibration(int theValue) {

    println("Saved Calibration of Person A in: ");
    kinect.startPoseDetection("Psi", person);
    //    kinect.saveCalibrationDataSkeleton(2, "calibration2.skel");
}

public void initVar() {

    errorY = 0;
    turnY = 0;
    integralY = 0;
    lastErrorY = 0;
    derivativeY = 0;

    errorX = 0;
    turnX = 0;
    integralX = 0;
    lastErrorX = 0;
    derivativeX = 0;
}



PVector jointPos = new PVector();
PVector jointPos_Proj = new PVector();
PVector headVec = new PVector();

float kpX, kiX, kdX, errorX, turnX, integralX, lastErrorX, derivativeX;
float kpY, kiY, kdY, errorY, turnY, integralY, lastErrorY, derivativeY;

int servoInitX = 90;
int servoInitY = 135;
int servoSeekX = servoInitX;
int servoSeekY = servoInitY;
int tempX = servoInitX;
boolean lockServo = true;

// draws a circle at the position of the head
public void circleForAHead(int userId) {

    //    kinect.getCoM(userId, jointPos);
    
   

    // get 3D position of a joint in the real world, and store it in jointPos.
//    kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_TORSO, jointPos);


//    float confidence = kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_TORSO, jointPos);
//    if(confidence > 0.5) {
    // convert real world point to projective space. Converting real word
    // millimeters of jointPos to pixels coordinates stored in jointPos_Proj.


//    kinect.convertRealWorldToProjective(jointPos, jointPos_Proj);
    
    
//    jointPos_Proj = handPosition;
    float distanceScalar = (kinect.depthHeight()/jointPos_Proj.z);
    headVec.x = jointPos_Proj.x - kinect.depthWidth()/2;
    headVec.y = jointPos_Proj.y - kinect.depthHeight()/2;

    errorY = headVec.y;
    integralY = integralY + errorY;
    derivativeY = errorY - lastErrorY;
    turnY = kpY * errorY + kiY * integralY + kdY * derivativeY;
//    turnY = 0.01*errorY + 0.0005*integralY + 0.001*derivativeY;

    errorX = headVec.x;
    integralX = integralX + errorX;
    derivativeX = errorX - lastErrorX;

    if (lockServo == false) {
//        turnY = kpY * errorY + kiY * integralY + kdY * derivativeY;
        turnX = kpX * errorX + kiX * integralX + kdX * derivativeX;
    } 
    else if (abs(headVec.x)<10) {
        initVar();
        lockServo = false;
    } 
    else {
//        turnY = 0.01*errorY + 0.0005*integralY + 0.001*derivativeY;
        turnX = 0.01f*errorX + 0.0005f*integralX + 0.001f*derivativeX;
    }

    servoSeekY = servoSeekY + parseInt(turnY);
    servoSeekX = servoSeekX - parseInt(turnX);

    updateServo(servoSeekX, servoSeekY);
    
    arduino.write(90+parseInt(errorX*0.1f)+"l");    // 6
    arduino.write(90+parseInt(errorX*0.1f)+"r");    // 7
    
    lastErrorY = errorY;
    lastErrorX = errorX;
    
    // a 200 pixel diameter head
    float headsize = 275;

    noFill();
    strokeWeight(2);
    // error X
    stroke(0xffddc92a);
    ellipse(jointPos_Proj.x+headVec.x, jointPos_Proj.y, 
    distanceScalar*headsize, distanceScalar*headsize);

    // error Y
    stroke(0xff81a3d0);
    ellipse(jointPos_Proj.x, jointPos_Proj.y+headVec.y, 
    distanceScalar*headsize, distanceScalar*headsize);

    // zero error
    stroke(0xffcc2a36);
    ellipse(jointPos_Proj.x, jointPos_Proj.y, 
    distanceScalar*headsize, distanceScalar*headsize);
//    }
}

public void updateServo(int servoXPOS, int servoYPOS) { 

    arduino.write(servoXPOS+"x");
    arduino.write(servoYPOS+"y");
}



// when a person ('user') enters the field of view
public void onNewUser(int userId)
{
    println("New User Detected - userId: " + userId);

    if (kinect.isTrackingSkeleton(person)) {
        println("Already tracking: "+person);
        kinect.stopTrackingSkeleton(userId);
        return;
    }

    person = userId;
    println("Sweep Searching...");
//    sweep = false;
    

    
}

// when a person ('user') leaves the field of view
public void onLostUser(int userId) {
    println("User Lost - userId: " + userId);
    if (kinect.isTrackingSkeleton(person)) {
        println("Lost - Already tracking: "+person);
        return;
    }

    
    lockServo = true;
    initVar();
//    sweep = true;
}

// when a user begins a pose
public void onStartPose(String pose, int userId) {
    println("Start of Pose Detected  - userId: "+userId+", pose: "+pose);

    // stop pose detection
    kinect.stopPoseDetection(userId);

    // start attempting to calibrate the skeleton
    kinect.requestCalibrationSkeleton(userId, true);
}

// when calibration begins
public void onStartCalibration(int userId) {
    
    println("Beginning Calibration - userId: " + userId);
    
}

// when calibaration ends - successfully or unsucessfully
public void onEndCalibration(int userId, boolean successfull) {
    println("Calibration of userId: "+userId+", successfull: "+successfull);

    if (successfull) {
        println("  User calibrated !!!");
        kinect.saveCalibrationDataSkeleton(userId, "calibration.skel");
        // begin skeleton tracking
        kinect.startTrackingSkeleton(userId);
    } 
    else { 
//        println("  Failed to calibrate user !!!");
        println("Sweep Searching...");
        sweep = true;
//        return;
    }
}


// Hand events
public void onCreateHands(int handId, PVector position, float time) {
    kinect.convertRealWorldToProjective(position, position);
    handPosition = position;
}

public void onUpdateHands(int handId, PVector position, float time) {
    kinect.convertRealWorldToProjective(position, position);
    handPosition = position;
}

public void onDestroyHands(int handId, float time) {
    kinect.addGesture("RaiseHand");
}

// gesture events
public void onRecognizeGesture(String strGesture, PVector idPosition, PVector endPosition) {
    kinect.startTrackingHands(endPosition);
    kinect.removeGesture("RaiseHand");
}


int graphSize = 300;
int graphZero = graphSize/2;

int[] graphPosX = new int[320];
int[] graphPosY = new int[320];

public void graphPID() {

    // Position graph X
    for(int i = 0; i<graphPosX.length; i++) {
         pidGraph.push("PosX", graphPosX[i]);
    }

    // Position graph Y
    for(int i = 0; i<graphPosY.length; i++) {
        pidGraph.push("PosY", graphPosY[i]);
    }

    // Zero line
    stroke(0xffd21838);
    line(0, kinect.depthHeight()+graphZero, 320,
         kinect.depthHeight()+graphZero);
      
    for(int i = 1; i<graphPosY.length;i++) {
        graphPosX[i-1] = graphPosX[i];
        graphPosY[i-1] = graphPosY[i];
    }
    graphPosX[graphPosX.length-1]=(int)errorX;
    graphPosY[graphPosY.length-1]=(int)errorY;
    
}


public void keyPressed() {
    switch(key) {
    case ' ':
        updateServo(servoInitX, servoInitY);
        servoSeekX = servoInitX;
        servoSeekY = servoInitY;
        initVar();
//        lockServo = true;
        break;
    case 'c':
        satCalib = true;
        break;
    case 's':
        satSearch = true;
        //            satSearchY = true;
        break;
    }

    switch(keyCode) {
    case LEFT:
        break;
    case RIGHT:
        break;
    case UP:
        frameSkip++;
        break;
    case DOWN:
        frameSkip--;
        break;
    }
}


    static public void main(String args[]) {
        PApplet.main(new String[] { "--bgcolor=#ECE9D8", "HeadTracking" });
    }
}
