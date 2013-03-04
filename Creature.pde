class Creature extends InteractiveObject {

  float     initialArea, currentArea;
  int       foodMax;
  int       foodMin;
  int       currentFood;
  int       metabolismRate;
  int       hungerThreshold;
  int       hungerGoneThreshold;
  int       foodDetectionRadius; // Creature will detect food within this distance from its position
  
  boolean   okToUpdateFood;
  
  InteractiveObject foodTarget;

  Brain  brain;
  String brainActivity;

  Creature() {
    initializeBrain();
    foodMax              = 100;
    foodMin              = 0;
    currentFood          = 55;
    hungerThreshold      = 50;
    hungerGoneThreshold  = 70;
    metabolismRate       = 2; // Represents number of seconds between metabolism adjustments; higher == slower
    foodDetectionRadius  = 20;
    
    okToUpdateFood       = false;
    lastTicCount         = 0;
  }

  void initializeBrain() {
    brain = new Brain();
    brainActivity = "Initializing...";
  }
  
  void setDestination(float x, float y){
    
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

  InteractiveObject findFood() {
    print("Calling Creature.findFood(). Override in your Creature subclass...\n");
   return null; 
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

