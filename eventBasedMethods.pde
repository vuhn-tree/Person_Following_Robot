
// -----------------------------------------------------------------
// SimpleOpenNI user events
PVector p2d = new PVector();
void onNewUser(SimpleOpenNI curContext, int userId)
{
    println("onNewUser - userId: " + userId);
    newUser = userId;
}

void onLostUser(SimpleOpenNI curContext, int userId)
{
    println("onLostUser - userId: " + userId);
    lostUser = userId;
}

void onVisibleUser(SimpleOpenNI curContext, int userId)
{
    if (trackingHands) {
        usr = userId;
    }
}

// -----------------------------------------------------------------
// hand events
void onNewHand(SimpleOpenNI curContext, int handId, PVector pos)
{
    println("onNewHand - handId: " + handId + ", pos: " + pos);
    trackingHands = true;
    p = pos;
}

void onTrackedHand(SimpleOpenNI curContext, int handId, PVector pos)
{
    println("onTrackedHand - handId: " + handId + ", pos: " + p2d );
    PVector p2d2 = new PVector();
    kinect.convertRealWorldToProjective(pos, p2d2);

    fill(100, 255, 100);
    text("Gesture Detected!", p2d2.x, p2d2.y);
}

void onLostHand(SimpleOpenNI curContext, int handId)
{
    println("onLostHand - handId: " + handId);
    trackingHands = false;
    tinc = 0;
}

// -----------------------------------------------------------------
// gesture events
void onCompletedGesture(SimpleOpenNI curContext, int gestureType, PVector pos)
{
    println("onCompletedGesture - gestureType: " + gestureType + ", pos: " + pos);

    moveMotors = true; 
    int handId = kinect.startTrackingHand(pos);
    println("hand stracked: " + handId);
}

