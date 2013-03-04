class World {
  // Inanimate food
  int       numFoodPellets = 25;
  ArrayList foodPellets;

  World() {
    setupWorld();
  } 

  void setupWorld() {
    // Establish food pellets
    foodPellets = new ArrayList();
    for (int i=0; i<numFoodPellets; i++) {
      Food f = new Food();
      foodPellets.add(f);
    }
  }

  void displayWorld() {
    // Display the inanimate food pellets
    for (int i=0; i< foodPellets.size(); i++) {
      Food f = (Food)foodPellets.get(i); 
      f.display();
    }
  }
  
  void removeFood(Food foodObj){
   print("World is removing foodPellet.\n"); 
   int idx = foodPellets.indexOf(foodObj);
   Food f = (Food)foodPellets.get(idx); 
   foodPellets.remove(f);
   f = null;
   foodObj = null;
  }

  InteractiveObject closestFood(PVector location, float radius) {
    for (int i=0; i<foodPellets.size(); i++) {
      InteractiveObject food    = (InteractiveObject)foodPellets.get(i);
      PVector foodPos = food.position;
      PVector vecBetween = PVector.sub(foodPos, location);
      float dist = vecBetween.mag();
      if(dist <= radius){
       return food; 
      }
    }
    return null;
  }
}

