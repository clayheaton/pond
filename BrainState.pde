class BrainState {
  String   name;
  Creature parentCreature;

  BrainState() {
  }

  void doActions() {
  }

  String checkConditions() {
    // An empty string means that the state shouldn't change.
    // To change states, return the name of the state to which you want to change.
    return ""; 
  }

  void entryActions() {
    parentCreature.brainActivity = "In generic BrainState -- use a subclass instead.";
  }

  void exitActions() {
  }
}

