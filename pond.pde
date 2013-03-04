Amoeba a;

int timer;
int lastMillisCount;

// Debugging measures
boolean stopLoop = false;
boolean debug    = false;

// Inanimate food
int     numFoodPellets = 25;
ArrayList foodPellets;

void setup() {
  size(800, 600);
  smooth();
  // frameRate(10);
  a = new Amoeba(width/2, height/2);
  timer = 0;
  lastMillisCount = 0;

  // Establish food pellets
  foodPellets = new ArrayList();
  for (int i=0; i<numFoodPellets; i++) {
    Food f = new Food();
    foodPellets.add(f);
  }
}

void draw() {
  // Background
  background(255);

  // Update the timer
  if (millis() - lastMillisCount >= 1000) {
    timer      += 1;
    lastMillisCount = millis();
  }

  // Display the inanimate food pellets
  for (int i=0; i< foodPellets.size(); i++) {
    Food f = (Food)foodPellets.get(i); 
    f.display();
  }

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

