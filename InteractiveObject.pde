// Anything that can eat or be eaten
// attack or be attacked -- includes inanimate food objects, etc.

class InteractiveObject {
  PVector   position;
  PVector   destination;
  float     initialSize;
  int       lastTicCount;

  InteractiveObject() {
  }

  // Helper method for calculating positions
  PVector positionWith(float angle, float length) {
    float x = cos(radians(angle)) * length;
    float y = sin(radians(angle)) * length;
    return new PVector(x, y);
  }
}

