class BrainState {
  String   name;
  Creature parentCreature;

  BrainState() {
  }

  void doActions() {
  }

  String checkConditions() {
    return "";
  }

  void entryActions() {
    parentCreature.brainActivity = "In generic BrainState -- use a subclass instead.";
  }

  void exitActions() {
  }
}

