World  world;
Amoeba a;

int timer;
int lastMillisCount;

// Debugging measures
boolean stopLoop = false;
boolean debug    = false;

void setup() {
  size(800, 600);
  smooth();
  // frameRate(10);
  a = new Amoeba(width/2, height/2);
  timer = 0;
  lastMillisCount = 0;
  world = new World();
}

void draw() {
  // Background
  background(255);

  // Update the timer
  if (millis() - lastMillisCount >= 1000) {
    timer      += 1;
    lastMillisCount = millis();
  }

  world.displayWorld();

  // Amoeba
  a.update();
  a.display();

  if (stopLoop) {
    noLoop();
  }
}

void mouseClicked() {
  a.setDestination(mouseX, mouseY);
}

void keyPressed() {

  // Simulate feeding the amoeba - for testing only
  if (key == 'f') {
    a.currentFood += 10;
    print("a.currentFood: " + a.currentFood + "\n");
  }
}

