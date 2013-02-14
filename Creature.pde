class Creature {
  Creature() {
  }

  // Helper method for calculating positions
  PVector positionWith(float angle, float length) {
    float x = cos(radians(angle)) * length;
    float y = sin(radians(angle)) * length;
    return new PVector(x, y);
  }

}

