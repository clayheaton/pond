class PerpVectorPack {
  // Store the original data
  PVector originalVector;

  // Keep track of values used to calculate points
  ArrayList<Float>   percentOfOriginalVector;
  ArrayList<Float>   magnitudeOfPerpendicularVector;
  ArrayList<Boolean> onRightSide;

  // Storage of calculated perpendicular line points
  ArrayList pointsOnLine;
  ArrayList perpVectorPoints;


  // Constructors
  PerpVectorPack(PVector origVector) {
    initializeLists();
    originalVector = origVector.get();
  }

  PerpVectorPack(PVector origVector, float perpVectDist, float perpVectMag, boolean rightSide) {    
    initializeLists();
    originalVector = origVector.get();
    addPerpVector(perpVectDist, perpVectMag, rightSide);
  }

  private void initializeLists() {
    pointsOnLine                    = new ArrayList();
    perpVectorPoints                = new ArrayList();

    percentOfOriginalVector         = new ArrayList<Float>();
    magnitudeOfPerpendicularVector  = new ArrayList<Float>();
    onRightSide                     = new ArrayList<Boolean>();
  }


  // Methods
  public void addPerpVector(float perpVectDist, float perpVectMag, boolean rightSide) {

    // Keep track of the values used to create the perpendicular points
    percentOfOriginalVector.add(perpVectDist);
    magnitudeOfPerpendicularVector.add(perpVectMag);
    onRightSide.add(rightSide);

    PVector full    = originalVector.get();
    float   fullMag = full.mag();

    // Determine where along the original vector the perpendicular vector should lie (lay?)
    full.normalize();
    full.mult(perpVectDist * fullMag);

    // Set the first local variable
    pointsOnLine.add(full.get());

    // Get the normal of the original full vector and normalize it
    PVector perpVector  = new PVector(-originalVector.y, originalVector.x);
    perpVector.normalize();

    // Determine if it should be on the right or left side of the original vector
    int dir = 1;
    if (!rightSide) dir = -1;

    // Make it the proper length
    perpVector.mult(fullMag * perpVectMag * dir);

    // Offset it from the origin
    perpVector.add(full);

    // Set the second local variable
    perpVectorPoints.add(perpVector.get());
  }



  public PVector ptOnOriginalLine() { 
    return ptOnOriginalLine(0);
  }

  public PVector ptOnOriginalLine(int idx) {
    PVector thePoint = (PVector)pointsOnLine.get(idx);
    return  thePoint.get();
  }



  public PVector perpVectorPt() { 
    return perpVectorPt(0);
  }

  public PVector perpVectorPt(int idx) {
    PVector thePoint = (PVector)perpVectorPoints.get(idx);
    return  thePoint.get();
  }



  public float perpVectorPtDistFromLine() {
    return perpVectorPtDistFromLine(0);
  }

  public float perpVectorPtDistFromLine(int idx) {
    PVector ptOnLine = ptOnOriginalLine(idx);
    PVector perpPt   = perpVectorPt(idx);
    PVector diff     = PVector.sub(perpPt, ptOnLine);
    return  diff.mag();
  }
}

