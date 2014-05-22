void graphPID() {
    // Graph Lines
    for(int i = 0 ;i<=width/10;i++) {
        strokeWeight(1);
        stroke(#743466);
        line((-frameCount%10)+i*10,kinect.depthHeight(),
             (-frameCount%10)+i*10,kinect.depthHeight()+graphSize);
        line(0, i*10+kinect.depthHeight(),width,i*10+kinect.depthHeight());
    }
    
    
    // Position graph X
    fill(#ddc92a);
    text("errorX: "+errorX, 15, kinect.depthHeight()+graphSize-40);
    noFill();
    strokeWeight(2);
    stroke(#ddc92a);
    beginShape();
    for(int i = 0; i<graphPosX.length; i++) {
        vertex(i, (kinect.depthHeight() + graphZero)-graphPosX[i]);
    }
    endShape();
    
    // Position graph Y
    fill(#81a3d0);
    text("errorY: "+errorY, 15, kinect.depthHeight()+graphSize-20);
    noFill();
    strokeWeight(2);
    stroke(#81a3d0);
    beginShape();
    for(int i = 0; i<graphPosY.length; i++) {
        vertex(i, (kinect.depthHeight() + graphZero)+graphPosY[i]);
    }
    endShape();
    
    // Zero line for graphPosY
    strokeWeight(2);
    stroke(#d21838);
    line(0, kinect.depthHeight()+graphZero, kinect.depthWidth(),
         kinect.depthHeight()+graphZero);
    for(int i = 1; i<graphPosY.length;i++) {
        graphPosX[i-1] = graphPosX[i];
        graphPosY[i-1] = graphPosY[i];
    }
    graphPosX[graphPosX.length-1]=(int)errorX;
    graphPosY[graphPosY.length-1]=(int)errorY;
}
