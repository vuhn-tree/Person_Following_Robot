import java.awt.*;
import processing.serial.*;
import cc.arduino.*;
import SimpleOpenNI.*;

Arduino arduino;
SimpleOpenNI  kinect;

PVector jointPos = new PVector();
PVector jointPos_Proj = new PVector();
PVector headVec = new PVector();

int camType = 1;

int servoInitX = 90;
int servoInitY = 135;

int servoXpin = 5;
int servoSeekX = servoInitX;
int servoYpin = 4;
int servoSeekY = servoInitY;

// PID X
float kpX = 0.0;
float kiX = 0.0;
float kdX = 0.0;
float tpX = 0;
float errorX = 0;
float turnX = 0;
int powerServoX = 0;
float integralX = 1;
float lastErrorX = 0;
float derivativeX = 0;
//float offset = 90;

int person = 1;
boolean foundHead = false;

// PID Y
float kpY = 0.0;
float kiY = 0.0;
float kdY = 0.0;
float tpY = 0;
float errorY = 0;
float turnY = 0;
int powerServoY = 0;
float integralY = 0;
float lastErrorY = 0;
float derivativeY = 0;

PFont font;
int graphSize = 300;
int graphZero = graphSize/2;
int[] graphPosX = new int[320];
int[] graphPosY = new int[320];

TextField kp_Input = new TextField("0.013", 6);
TextField ki_Input = new TextField("0.0007", 6);
TextField kd_Input = new TextField("0.04", 6);

TextField kpY_Input = new TextField("0.009", 6);
TextField kiY_Input = new TextField("0.0005", 6);
TextField kdY_Input = new TextField("0.04", 6);

float torsoOffset = 80;
int trackOption = 0;
String trackOptionLabel[] = {"Torso", "Head"};
boolean graphOption = false;
int buttonFill = 0;
int satFill = 0;

int searchBoxDim = 100;

PImage imgRGB;

float R = 0;
float G = 0;
float B = 0;

float H = 0;
float S = 0;
float BR = 0;

int[] sat = new int[255];
int[] prevSat = new int[255];
int satAccur = 0;
boolean satCalib = false;
int calMouseX = 0;
int calMouseY = 0;

boolean satHist = false;
boolean satSearch = false;

//int[] satSearchSq = new int[255];
int[][] satSearchArr = new int[640][255];
int xSearch = 0;
int ySearch = 200;

int maxSatAccur = 0;
int searchedX = 0;

int[] satBuffer = new int[640];

public void setup()
{
    arduino = new Arduino(this, Arduino.list()[4]);
    println(Arduino.list());
    
    arduino.pinMode(servoXpin, Arduino.OUTPUT);
    arduino.pinMode(servoYpin, Arduino.OUTPUT);
    
    arduino.analogWrite(servoXpin, servoSeekX);
    arduino.analogWrite(servoYpin, servoSeekY);
    
    font = createFont("FrankRuehl-48", 132);
    textFont(font);
    
    // instantiate a new kinect
    kinect = new SimpleOpenNI(this);
    kinect.setMirror(true);
    
    // enable depthMap generation
    kinect.enableDepth();
    kinect.enableRGB();
    
    // enable skeleton generation for all joints
    kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
    
    background(0, 0, 0);
    smooth();
    
    // create a window the size of the depth information
    size(kinect.depthWidth(), kinect.depthHeight()+graphSize);
    
    add(kp_Input);
    add(ki_Input);
    add(kd_Input);
    
    add(kpY_Input);
    add(kiY_Input);
    add(kdY_Input);
    
    frameRate(60);
    
}

public void draw() {

    
    kinect.update();
    if(camType == 0) {
        image(kinect.depthImage(), 0, 0);
    }
    if(camType == 1) {
        imgRGB = kinect.rgbImage();
//        image(imgRGB, 0, 0);
    }
    
    textSize(14);
    fill(#d21838);
    text("kpX           kiX            kdX          " +
         "kpY           kiY            kdY", 120, 50);
    
    kpX = parseFloat(kp_Input.getText());
    kiX = parseFloat(ki_Input.getText());
    kdX = parseFloat(kd_Input.getText());
    
    kpY = parseFloat(kpY_Input.getText());
    kiY = parseFloat(kiY_Input.getText());
    kdY = parseFloat(kdY_Input.getText());
    
    fill(0);
    stroke(0);
    strokeWeight(0);
    rect(0, kinect.depthHeight(), kinect.depthWidth(), graphSize);
    

    
    if(graphOption==true) {
        graphPID();
        
    }
    
    // Text error information
    textSize(14);
    fill(#8cb990);
    text("Head Tracking Kinect Robot by Richard Vu        Frame Rate:"+frameRate+
         "\nservoX: " + servoSeekX +
         "  servoY: " + servoSeekY +
         "\nKp: "+kpX+
         "  kiX: "+kiX+
         "  kdX: "+kdX+
         "\nKpY: "+kpY+
         "  kiY: "+kiY+
         "  kdY: "+kdY+
         "\nTrack Option: "+trackOptionLabel[trackOption], 15, kinect.depthHeight() + 20);
    
    
    if(satHist==true) {
        sat = new int[255];
        satSearchArr = new int[kinect.depthWidth()][255];
        
        loadPixels();
        imgRGB.loadPixels();
        
        for (int y = 0; y < imgRGB.height; y++) {
            int m = 0;
            satBuffer = new int[kinect.depthWidth()];
            for (int x = 0; x < imgRGB.width; x++) {
                int loc = x + y*imgRGB.width;
                
                float r = red(imgRGB.pixels[loc]);
                float g = green(imgRGB.pixels[loc]);
                float b = blue(imgRGB.pixels[loc]);
                
                float h = hue(imgRGB.pixels[loc]);
                float s = saturation(imgRGB.pixels[loc]);
                float br = brightness(imgRGB.pixels[loc]);
                
                if(x==mouseX && y==mouseY && frameCount%5==0) {
                    R = r;
                    G = g;
                    B = b;
                    
                    H = h;
                    S = s;
                    BR = br;
                    
                }
                
                if(satSearch==true) {
                    if(y<ySearch+100 && y>ySearch) {
                        if(x<kinect.depthWidth() && x>0) {
                            satBuffer[m] = int(s);
                            m++;
                        }
                    }
                }
                
                if(x>mouseX-50 && x<mouseX+50 && y>mouseY-50 && y<mouseY+50) {
                    sat[int(s)]++;
                }
                // Set the display pixel to the image pixel
                pixels[loc] = color(r,g,b);
            }
            
            if(y<ySearch+100 && y>ySearch && satSearch==true) {
                for(int j=0; j<kinect.depthWidth()-100; j++) {
                    for(int i=0; i<100; i++) {
                        satSearchArr[j][satBuffer[i+j]]++;
                    }
                }
            }
        }
        updatePixels();
        
//        satAccur = 0;
//        for(int i=0; i<255; i++) {
//            if(abs(prevSat[i]-sat[i])<5) {
//                satAccur++;
//            }
//        }

        if(satCalib==true) {
            calMouseX = mouseX;
            calMouseY = mouseY;
            prevSat = sat;
            satCalib = false;
        
        }

        fill(#dee4fa);
        strokeWeight(0);
        rect(mouseX+10, mouseY-15, 200, 75);
        fill(#cc2a36);
        text(int(R), mouseX+15, mouseY);
        fill(#599653);
        text(int(G), mouseX+15, mouseY+15);
        fill(#003b6f);
        text(int(B), mouseX+15, mouseY+30);
        
        fill(#eb6841);
        text("Hue: "+H, mouseX+65, mouseY);
        text("Sat: "+S, mouseX+65, mouseY+15);
        text("Bri: "+BR, mouseX+65, mouseY+30);
        
        if(satSearch == true) {
            fill(#003b6f);
//            text("satAccur: "+satAccur, mouseX+15, mouseY+45);


            for(int i=0; i<kinect.depthWidth(); i++) {
                satAccur = 0;
                for(int j=0; j<255; j++) {
                    if(abs(prevSat[j]-satSearchArr[i][j])<10) {
                        satAccur++;
                    }
                    if(satAccur > maxSatAccur) {
                        maxSatAccur = satAccur;
                        searchedX = i;
                    }
                }
            }
            maxSatAccur = 0;
        } 
        
        noFill();
        strokeWeight(1);
        stroke(#599653);
        rect(searchedX, ySearch, 100, 100);
        
        noFill();
        strokeWeight(1);
        stroke(#d21838);
        rect(mouseX-50, mouseY-50, 100, 100);
        for(int i=0; i<255; i++) {
            
            line(100+2*i, kinect.depthHeight()+260,
                 100+2*i, kinect.depthHeight()+260-(int(sat[i])));
            
        }
        
        
        noFill();
        strokeWeight(1);
        stroke(#003b6f);
        rect(calMouseX-50, calMouseY-50, 100, 100);
        for(int i=0; i<255; i++) {
            
            line(101+2*i, kinect.depthHeight()+260,
                 101+2*i, kinect.depthHeight()+260-(int(prevSat[i])));
            
        }
        
    } else {
        
        image(imgRGB, 0, 0);
        
    }
    
    switch (trackOption) {
        case 0:
            if(Float.isNaN(turnX)) {
                initVar();
            }
            if(foundHead == true) {
                circleForAHead(person);
            }
            break;
            
        case 1:
            if(kinect.isTrackingSkeleton(person)) {
                circleForAHead(person);
            }
            break;
            
        default:
            break;
    }
    
    fill(buttonFill);
    stroke(#d21838);
    strokeWeight(1);
    rect(kinect.depthWidth()-100, kinect.depthHeight()+graphSize-30, 100, 30);
    
    fill(satFill);
    stroke(#d21838);
    strokeWeight(1);
    rect(kinect.depthWidth()-200, kinect.depthHeight()+graphSize-30, 100, 30);
}


public void mouseClicked() {
    
    if(mouseX<kinect.depthWidth()-100 && mouseX>kinect.depthWidth()-200 &&
       mouseY<kinect.depthHeight()+graphSize && mouseY>kinect.depthHeight()+graphSize-30 &&
       satHist==false) {
        satHist= true;
        satFill = 255;
    } else {
        satHist = false;
        satFill = 0;
    }
 
    if(mouseX<kinect.depthWidth() && mouseX>kinect.depthWidth()-100 &&
       mouseY<kinect.depthHeight()+graphSize && mouseY>kinect.depthHeight()+graphSize-30 &&
       graphOption==false) {
        graphOption = true;
        buttonFill = 255;
    } else {
        graphOption = false;
        buttonFill = 0;
    }
       
}

//void servoSpeed(int pos, int speed) {
//    int val = arduino.analogRead(servoXpin);            // reads the value of the potentiometer (value between 0 and 1023)
////    val = map(int(val), 0, 1023, 0, 179);     // scale it to use it with the servo (value between 0 and 180)
//    for(int i=int(val); i<pos; i++) {
////        if(frameCount%10 == 0) {
//            arduino.analogWrite(servoXpin, i);
//            delay(25);
////        }
//        
//    }
//}

public void initVar() {

    tpY = 0;
    errorY = 0;
    turnY = 0;
    powerServoY = 0;
    integralY = 0;
    lastErrorY = 0;
    derivativeY = 0;
    
    tpX = 0;
    errorX = 0;
    turnX = 0;
    powerServoX = 0;
    integralX = 0;
    lastErrorX = 0;
    derivativeX = 0;
    
    powerServoX = 0;
    powerServoY = 0;
    
}

//public class Graph() {
//
//
//    public void sup() {
//
//    }
//}
//


