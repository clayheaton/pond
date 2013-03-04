class Food extends InteractiveObject {

  ArrayList outsidePoints;
  PVector   insidePosition;

  int       insideRadius  = 5;
  int       outsideRadius = insideRadius + (int)random(insideRadius);
  int       ticsTilCenterJiggle = 2 + (int)random(30);

  Food() {
    float x = random(width);
    float y = random(height);
    setUpFood(new PVector(x, y));
  } 

  Food(PVector location) {
    setUpFood(location);
    // Create points between outside and inside radius
  }

  void setUpFood(PVector location) {
    insidePosition = new PVector(0,0);
    
    outsidePoints = new ArrayList();
    position = location;
    int   numPoints   = 4 + (int)random(3);
    float angleOffset = 360.0 / numPoints;

    for (int i=0; i < numPoints; i++) {
      float angle = (i + 1) * angleOffset;
      float ptLen = insideRadius + random(outsideRadius - insideRadius);
      PVector pt  = positionWith(angle, ptLen);
      outsidePoints.add(pt);
    }
  }

  void display() {
    stroke(100, 100);
    fill(200, 255, 0, 50);
    pushMatrix();
    translate(position.x, position.y);

    beginShape();
    // First control point
    PVector firstPt = (PVector)outsidePoints.get(0);
    curveVertex(firstPt.x, firstPt.y);

    for (int i = 0; i < outsidePoints.size(); i++) {
      PVector pt = (PVector)outsidePoints.get(i);
      curveVertex(pt.x, pt.y);
    }

    curveVertex(firstPt.x, firstPt.y);
    PVector secondPt = (PVector)outsidePoints.get(1);
    curveVertex(secondPt.x, secondPt.y);
    endShape();

    // Vary the posiiton of the center ellipse
    if (timer != 0 && timer % ticsTilCenterJiggle == 0) {
      float x = random(2);
      float y = random(2);
      float xmod = random(100);
      float ymod = random(100);
      if (xmod < 50) x *= -1;
      if (ymod < 50) y *= -1;
      insidePosition.x = x;
      insidePosition.y = y;
    }
    
    // Draw the center ellipse
    fill(200);
    ellipse(insidePosition.x,insidePosition.y,2,2);

    popMatrix();
  }
}

