// Anything that can eat or be eaten
// attack or be attacked -- includes inanimate food objects, etc.

class InteractiveObject {
  PVector   position;
  PVector   destination;
  float     initialSize;
  int       lastTicCount;
  boolean   canFlee = true;
  
  int       foodValue = 25;

  InteractiveObject() {
  }
  
  void consume(InteractiveObject obj){
    print("Generic InteractiveObject.consume() method. Implement something more specific in the subclass.\n");
    obj.beConsumedBy(this);
  }
  
  void beConsumedBy(InteractiveObject obj){
    print("Generic InteractiveObject.consumedBy() method. Implement something more specific in the subclass.\n");
  }
  
  void die() {
    print("Generic InteractiveObject die() method. Implement something more specific in the subclass.\n");
  }

  // Helper method for calculating positions
  PVector positionWith(float angle, float length) {
    float x = cos(radians(angle)) * length;
    float y = sin(radians(angle)) * length;
    return new PVector(x, y);
  }
}

