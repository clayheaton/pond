Amoeba a;

// Debugging measures
boolean stopLoop = false;
boolean debug    = false;

void setup() {
  size(800, 600);
  smooth();
  // frameRate(10);
  a = new Amoeba(width/2, height/2);
}

void draw() {
  background(255);
  a.update();
  a.display();
  if (stopLoop) {
    noLoop();
  }
}

void mouseClicked() {
  a.setDestination(mouseX, mouseY);
}

