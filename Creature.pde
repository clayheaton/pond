class Creature {
  PVector   position;
  PVector   destination;
  float     initialArea, currentArea;
  int       foodMax;
  int       foodMin;
  int       currentFood;
  int       metabolismRate;
  int       lastTicCount;
  

  boolean   okToUpdateFood;

  Brain  brain;
  String brainActivity;

  Creature() {
    initializeBrain();
    foodMax              = 100;
    foodMin              = 0;
    currentFood          = 50;
    metabolismRate       = 5; // Represents number of seconds between metabolism adjustments; higher == slower
    okToUpdateFood       = false;
    lastTicCount         = 0;
  }

  void initializeBrain() {
    brain = new Brain();
    brainActivity = "Initializing...";
  }

  void updateFoodLevel() {

    if (metabolismRate == 1) {
      if (timer > lastTicCount) {
        // print("food: " + currentFood + "\n");
        currentFood -=1;
        lastTicCount = timer;
      }
    } 
    else {

      if (okToUpdateFood) {
        if (timer % metabolismRate == 0) {
          currentFood   -= 1;
          okToUpdateFood = false;
          // print("food: " + currentFood + "\n");
        }
      }

      if (timer % metabolismRate > 0) okToUpdateFood = true;
    }
  }

  // Helper method for calculating positions
  PVector positionWith(float angle, float length) {
    float x = cos(radians(angle)) * length;
    float y = sin(radians(angle)) * length;
    return new PVector(x, y);
  }

  float creatureArea(ArrayList nodes) { 
    // http://www.mathopenref.com/coordpolygonarea2.html
    int   numPoints = nodes.size();
    float area      = 0;
    int   j         = numPoints - 1;

    for (int i = 0; i < numPoints; i++) { 
      PVector iNode = (PVector)nodes.get(i);
      PVector jNode = (PVector)nodes.get(j);
      area = area +  (jNode.x + iNode.x) * (jNode.y - iNode.y); 
      j = i;
    }
    return area/2;
  }
}

