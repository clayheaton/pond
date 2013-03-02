import java.util.Iterator;
import java.util.Map;

class Brain {
  HashMap  states;
  BrainState activeState;

  Brain() {
    states = new HashMap();
  }

  void addState(String stateName, BrainState state) {
    states.put(stateName, state);
  }

  void setState(String stateName) {
    if (activeState != null) {
      activeState.exitActions(); // End the brain state
    }

    activeState = (BrainState)states.get(stateName);
    activeState.entryActions(); // Start the new brain state
  }

  void think() {
    if (activeState == null) {
      return;
    }
    
    activeState.doActions();
    String newState = activeState.checkConditions();

    // Nothing to change to
    if (newState.trim().equals("")) {
      return;
    } 
    else {
      setState(newState);
    }
  }
}

