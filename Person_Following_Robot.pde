
import processing.serial.*;
import SimpleOpenNI.*;
import controlP5.*;
import java.awt.*;

ControlP5 cp5;
Chart pidGraph;
Serial arduino, icreate;
SimpleOpenNI kinect;

int kWidth, kHeight, newUser, lostUser, person=1, 
    frameSkip=1, usr=1, tinc=0, leftSlow, rightSlow;
boolean moveMotors = false, trackingHands = false;
PVector p = new PVector();

public void setup() {

    println(Serial.list());
    arduino = new Serial(this, Serial.list()[6], 115200);
    icreate = new Serial(this, Serial.list()[7], 57600);

    PFont font = createFont("arial", 16);
    textFont(font);

    kinect = new SimpleOpenNI(this);
    kinect.setMirror(true);
    kinect.enableDepth();
    kinect.enableRGB();
    kinect.enableUser();
    kWidth = kinect.rgbWidth();
    kHeight = kinect.rgbHeight();

    kinect.enableHand();
    kinect.startGesture(SimpleOpenNI.GESTURE_WAVE);  

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
    pidGraph.setColors("PosX", #ddc92a);
    pidGraph.setData("PosX", new float[320]);
    pidGraph.addDataSet("PosY");
    pidGraph.setColors("PosY", #81a3d0);
    pidGraph.setData("PosY", new float[320]);

    cp5.addTextfield("KP X")
        .setPosition(360, 520)
            .setSize(70, 25)
                .setFont(font)
                    .setAutoClear(false)
                        .setColor(color(255, 0, 0))
                            .setText("0.0100")
                                ;

    cp5.addTextfield("KI X")
        .setPosition(440, 520)
            .setSize(70, 25)
                .setFont(font)
                    .setAutoClear(false)
                        .setColor(color(255, 0, 0))
                            .setText("0.0005")
                                ;

    cp5.addTextfield("KD X")
        .setPosition(520, 520)
            .setSize(70, 25)
                .setFont(font)
                    .setAutoClear(false)
                        .setColor(color(255, 0, 0))
                            .setText("0.0008")
                                ;

    cp5.addTextfield("KP Y")
        .setPosition(360, 570)
            .setSize(70, 25)
                .setFont(font)
                    .setAutoClear(false)
                        .setColor(color(255, 0, 0))
                            .setText("0.0100")
                                ;

    cp5.addTextfield("KI Y")
        .setPosition(440, 570)
            .setSize(70, 25)
                .setFont(font)
                    .setAutoClear(false)
                        .setColor(color(255, 0, 0))
                            .setText("0.0002")
                                ;

    cp5.addTextfield("KD Y")
        .setPosition(520, 570)
            .setSize(70, 25)
                .setFont(font)
                    .setAutoClear(false)
                        .setColor(color(255, 0, 0))
                            .setText("0.0003")
                                ;

    kpX = parseFloat(cp5.get(Textfield.class, "KP X").getText());
    kiX = parseFloat(cp5.get(Textfield.class, "KI X").getText());
    kdX = parseFloat(cp5.get(Textfield.class, "KD X").getText());

    kpY = parseFloat(cp5.get(Textfield.class, "KP Y").getText());
    kiY = parseFloat(cp5.get(Textfield.class, "KI Y").getText());
    kdY = parseFloat(cp5.get(Textfield.class, "KD Y").getText());

    cp5.addToggle("moveMotors")
        .setPosition(440, 700)
            .setSize(75, 20)
                .setCaptionLabel("MOVE MOTORS")
                    .setMode(ControlP5.SWITCH)
                        ;

    initVar();
}

public void draw() {

    if (frameCount%frameSkip==0) {
        image(kinect.rgbImage(), 0, 0);
        //        image(kinect.depthImage(), 0, 0);
        kinect.update();

        fill(0);
        stroke(0);
        strokeWeight(0);
        rect(0, kHeight, kWidth, graphSize);

        IntVector userList = new IntVector();
        kinect.getUsers(userList);
        PVector posRealWorld = new PVector();
        PVector posProjected = new PVector();

        textSize(40);
        for (int i = 0; i <userList.size(); i++)
        {

            int userId = userList.get(i);
            // lets get user's center of mass coordinates in real world coordinate system
            kinect.getCoM(userId, posRealWorld);

            // let's convert the center of mass position mapped to 640*480 
            kinect.convertRealWorldToProjective(posRealWorld, posProjected);

            fill(100, 255, 100);
            text(userId, posProjected.x, posProjected.y);
        } 
        textSize(16);

        if (kinect.getCoM(usr, jointPos)) {
            if (Float.isNaN(error.x) || Float.isNaN(error.y)) {
                initVar();
            }
            kinect.convertRealWorldToProjective(jointPos, jointPos_Proj);
            centerTorso();
            leftSlow = leftMotor;
            rightSlow = rightMotor;
        } 
        else {

            if (trackingHands && tinc < 10) {
                if (Float.isNaN(error.x) || Float.isNaN(error.y)) {
                    initVar();
                }
                kinect.convertRealWorldToProjective(p, p2d);
                jointPos_Proj.x = p2d.x;
                jointPos_Proj.y = p2d.y+50;
                jointPos_Proj.z = followDist;
                centerTorso();
                fill(100, 255, 100);
                text("Gesture Detected!", jointPos_Proj.x, jointPos_Proj.y);
                tinc++;
            }
            else {
                initVar();
                if (frameCount%15==0) {
                    leftSlow = leftSlow/2;
                    rightSlow = rightSlow/2;
                    move(leftSlow, rightSlow);
                }
            }
        }

        graphPID();

        updateServo(servoSeekX, servoSeekY);

        fill(#8cb990);
        text("Person Following Robot by Richard Vu"+
            "\nservoX: " + servoSeekX + "  servoY: " + servoSeekY +
            "\nerror.x: "+error.x+
            "\nerror.y: "+error.y+
            "\nerror.z: "+error.z, 15, kHeight + 20);

        text("New User: "+newUser+"   Lost User: "+lostUser, 360, 680);
    }
}

void controlEvent(ControlEvent theEvent) {
    if (theEvent.isAssignableFrom(Textfield.class)) {
        kpX = parseFloat(cp5.get(Textfield.class, "KP X").getText());
        kiX = parseFloat(cp5.get(Textfield.class, "KI X").getText());
        kdX = parseFloat(cp5.get(Textfield.class, "KD X").getText());

        kpY = parseFloat(cp5.get(Textfield.class, "KP Y").getText());
        kiY = parseFloat(cp5.get(Textfield.class, "KI Y").getText());
        kdY = parseFloat(cp5.get(Textfield.class, "KD Y").getText());
    }
}

public void initVar() {
    error.y = 0;
    turnY = 0;
    integralY = 0;
    lastErrorY = 0;
    derivativeY = 0;

    error.x = 0;
    turnX = 0;
    integralX = 0;
    lastErrorX = 0;
    derivativeX = 0;

    error.z = 0;
}

