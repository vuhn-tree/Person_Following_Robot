
int graphSize = 300;
int graphZero = graphSize/2;

int[] graphPosX = new int[320];
int[] graphPosY = new int[320];

void graphPID() {

    // Position graph X
    for (int i = 0; i<graphPosX.length; i++) {
        pidGraph.push("PosX", graphPosX[i]);
    }

    // Position graph Y
    for (int i = 0; i<graphPosY.length; i++) {
        pidGraph.push("PosY", graphPosY[i]);
    }

    // Zero line
    stroke(#d21838);
    line(0, kinect.depthHeight()+graphZero, 320, 
        kinect.depthHeight()+graphZero);

    for (int i = 1; i<graphPosY.length;i++) {
        graphPosX[i-1] = graphPosX[i];
        graphPosY[i-1] = graphPosY[i];
    }
    graphPosX[graphPosX.length-1]=(int)error.x;
    graphPosY[graphPosY.length-1]=(int)error.y;
}

