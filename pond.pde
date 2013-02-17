Amoeba a;

// Debugging measures
boolean stopLoop = false;
boolean debug    = true;

void setup() {
  size(800, 600);
  // frameRate(10);
  a = new Amoeba(width/2, height/2);
}

void draw() {
  background(255);
  a.update();
  a.display();
  if(stopLoop) {
   noLoop(); 
  }
}

void mouseClicked() {
  a.setDestination(mouseX,mouseY);
}

