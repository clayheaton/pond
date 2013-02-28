class Creature {
  PVector   position;
  PVector   destination;
  float     initialArea, currentArea;

  Brain brain;

  Creature() {
    initializeBrain();
  }

  void initializeBrain() {
    brain = new Brain();
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

