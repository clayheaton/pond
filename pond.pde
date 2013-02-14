Amoeba a;

void setup() {
  size(800, 600);
  //frameRate(3);
  a = new Amoeba(width/2, height/2);
}

void draw() {
  background(255);
  a.update();
  a.display();
}

void mouseClicked() {
  a.setDestination(mouseX,mouseY);
}

