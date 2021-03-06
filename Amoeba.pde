import java.util.*;

// List amoeba brain states here so that we can refer to them
// as variables in the rest of the code & use this as reference
String amoebaForaging = "amoeba_brain_state_foraging";
String amoebaResting  = "amoeba_brain_state_resting";
String amoebaDying    = "amoeba_brain_state_dying";

class Amoeba extends Creature {
  float   size;
  PVector footDestination;

  int   initialSize     = 30 + (int)random(50);
  float initialRadius   = initialSize   * 0.5;
  float footTolerance   = initialRadius * 0.5;
  float footTravelLimit = initialSize   * 2.0;
  float footTooClose    = initialSize   * 0.75;

  int   angleTolerance  = 45;
  float areaTolerance   = 0.2; // Amoeba area grow or shrink by 20 percent without triggering a fix

  int   numBaseNodes    = 18;
  int   maxNodes        = 20;
  int   nodeChainLength = 2;

  float baseAngleSpacing;
  float angleSpacing;

  // Protected as references
  ArrayList baseNodes;
  ArrayList<Float> baseNodesAngles;
  ArrayList contractedNodes;

  // Used during execution
  ArrayList baseNodesForResting;

  ArrayList expandedNodes;
  ArrayList<Float> expandedNodesAngles;
  ArrayList<Integer>expandedNodesAnglesQuadrants;
  ArrayList<Boolean> indicesToCollapse; 

  int       closestNodeIndex;
  boolean   closestNodeSelected;

  boolean   isMoving;
  boolean   hasFoodTarget;
  boolean   footAtTarget;
  boolean   setNewFootTarget;

  boolean   achievedRest;

  boolean   collapsingIndicesSet;

  float     movementSpeed                  = 0.06;
  float     nodeMovementSpeed              = 0.08; // 0.1
  float     newFootDestMagMultiplier       = 2.0;
  float     chainedNodeFastSpeedMultiplier = 3.0;

  // Copies of the originals that we can revert to after speed changes
  float     movementSpeedOrig     = movementSpeed;
  float     nodeMovementSpeedOrig = nodeMovementSpeed;

  boolean   slowedDown;
  boolean   spedUp;

  boolean   areaOutOfRange;
  boolean   areaTooSmall;
  boolean   expand;
  boolean   contract;





  Amoeba(float x, float y) {
    isMoving            = false;
    position            = new PVector(x, y);
    destination         = new PVector(x, y);
    footDestination     = new PVector(x, y);

    baseNodes           = new ArrayList();
    baseNodesAngles     = new ArrayList<Float>();
    contractedNodes     = new ArrayList();
    baseNodesForResting = new ArrayList();
    expandedNodes       = new ArrayList();
    expandedNodesAngles = new ArrayList<Float>();
    expandedNodesAnglesQuadrants = new ArrayList<Integer>();
    indicesToCollapse   = new ArrayList<Boolean>();

    size = initialSize;
    closestNodeIndex    = 0; // Initialize to avoid error
    closestNodeSelected = false;

    achievedRest        = true;
    slowedDown          = false;
    spedUp              = false;
    setNewFootTarget    = false;
    areaOutOfRange      = false;
    areaTooSmall        = false;
    expand              = false;
    contract            = false;

    foodDetectionRadius = initialSize * 2;
    metabolismRate      = 5;

    initializeNodes();
    setUpBrain();
  }





  void initializeNodes() {
    baseAngleSpacing = 360.0 / numBaseNodes;
    angleSpacing = baseAngleSpacing;

    for (int i = 0; i < numBaseNodes; i++) {
      float thisAngle = i * angleSpacing;
      baseNodesAngles.add(thisAngle);
      expandedNodesAngles.add(thisAngle);

      if (thisAngle >=0 && thisAngle < 90) {
        expandedNodesAnglesQuadrants.add(1);
      } 
      else if (thisAngle >= 90 && thisAngle < 180) {
        expandedNodesAnglesQuadrants.add(2);
      } 
      else if (thisAngle >= 180 && thisAngle < 270) {
        expandedNodesAnglesQuadrants.add(3);
      } 
      else {
        expandedNodesAnglesQuadrants.add(4);
      }

      float adj = random(footTolerance);
      if (random(100) > 50) {
        adj *= -1;
      }

      float len = initialRadius + adj;
      PVector toAdd = positionWith(thisAngle, len);

      baseNodes.add(toAdd.get());
      baseNodesForResting.add(toAdd.get());
      expandedNodes.add(toAdd.get());

      // Determine the contracted nodes (for parts of the amoeba that must shrink)
      float contractedLength = initialRadius - random(footTolerance);
      contractedNodes.add(positionWith(thisAngle, contractedLength));

      // Initialize all to true
      indicesToCollapse.add(true);
    }

    // Calculate the initial area
    initialArea = abs(creatureArea(expandedNodes));
    // print("Creature initial area: " + initialArea + "\n");
    // TODO: recalcualte the initialArea if the creature grows by eating something.
  }




  void setUpBrain() {

    AmoebaBrainStateForaging absf = new AmoebaBrainStateForaging(this);
    AmoebaBrainStateResting  absr = new AmoebaBrainStateResting(this);
    AmoebaBrainStateDying    absd = new AmoebaBrainStateDying(this);

    brain.addState(amoebaForaging, absf);
    brain.addState(amoebaResting, absr);
    brain.addState(amoebaDying, absd);

    // Set the active state
    brain.setState(amoebaResting);
  }




  void recalculateBaseNodesForResting() {

    for (int i = 0; i < numBaseNodes; i++) {
      float thisAngle = baseNodesAngles.get(i); //i * angleSpacing;

      float adj = random(footTolerance);
      if (random(100) > 50) {
        adj *= -1;
      }

      float   len   = initialRadius + adj;
      PVector toAdd = positionWith(thisAngle, len);
      baseNodesForResting.set(i, toAdd);

      // Determine the contracted nodes (for parts of the amoeba that must shrink)
      float contractedLength = initialRadius - random(footTolerance);
      contractedNodes.set(i, positionWith(thisAngle, contractedLength));
    }
  }





  void resetCollapsible() {
    for (int i = 0; i < numBaseNodes; i++) {
      indicesToCollapse.set(i, true);
    }
  }




  void setDestination(PVector dest    ) { 
    setDestination(dest.x, dest.y);
  }
  void setDestination(float x, float y) {
    destination.x = x;
    destination.y = y;

    footDestination = destination.get();
    isMoving             = true;
    closestNodeSelected  = false;
    footAtTarget         = false;
    setNewFootTarget     = false;
    collapsingIndicesSet = false;
    achievedRest         = false;
    spedUp               = false;
    slowedDown           = false;

    // Reset the indices
    resetCollapsible();
    recalculateBaseNodesForResting();
  }




  void update() {
    brain.think();
    updateFoodLevel();
    performMove();
    //print("Amoeba brain: " + brainActivity + "\n");
  }





  void performMove() {
    if (isMoving) {
      PVector distToDestination = PVector.sub(destination, position);
      PVector velocity = distToDestination.get();

      // Stop the move if we are close enough to the destination
      float dist = distToDestination.mag();
      if (dist <= 1.0) {
        destination = position.get();
        isMoving            = false;
        closestNodeSelected = false;
        footAtTarget        = true;
        return;
      }

      velocity.normalize();
      velocity.mult(movementSpeed);
      position.add(velocity);

      if (!footAtTarget) {
        //print("nodes moving " + millis() + " \n");
        performNodeMovements();
      }
    } 
    else {
      // The amoeba is at rest. Move to base position and then to 
      // subsequent iterations of base position
      if (!achievedRest) {
        // Move into resting position after a move
        moveToRest();
      } 
      else {
        // Random chance to move to variation on base position
        moveToRandomRest();
      }
    }

    checkAreaForFit();
  }




  void checkAreaForFit() {
    currentArea = abs(creatureArea(expandedNodes));
    // print("currentArea: " + currentArea + "\n");

    float big, little;
    areaTooSmall = false;
    if (initialArea >= currentArea) {
      // print("  initialArea larger than currentArea\n");
      big    = initialArea;
      little = currentArea;
      areaTooSmall = true;
    } 
    else {
      // print("  currentArea larger than initialArea\n");
      big    = currentArea;
      little = initialArea;
    }

    if ((big - little) / initialArea < areaTolerance) {
      // print("  ... but is within bounds.\n");
      areaOutOfRange = false;
      expand   = false;
      contract = false;
      return;
    } 
    else {
      // print("  (big - little) / initialArea = (" + big + " - " + little + ") / " + initialArea + " = " + ((big - little)/initialArea) + "\n");
      areaOutOfRange = true;
    }

    // Probably can remove the areaOutOfRange variable
    if (areaOutOfRange) {
      if (areaTooSmall) {
        expand   = true;
        contract = false;
      } 
      else {
        expand   = false;
        contract = true;
      }
    }
  }



  void performNodeMovements() {
    if (!closestNodeSelected) {
      selectClosestNode();
    }

    PVector closestNode = (PVector)expandedNodes.get(closestNodeIndex);
    PVector closestNodeCopy = closestNode.get();
    closestNodeCopy.add(position.get());

    PVector distVect = PVector.sub(footDestination, closestNodeCopy);
    float dist = distVect.mag();

    if (debug) {
      noFill();
      stroke(0, 255, 0);
      strokeWeight(1);
      line(footDestination.x, footDestination.y, position.x, position.y);
    }

    // Stop moving if the closest foot is close enough to the destination.
    // This needs to change when the amoeba has a food target.

    if (setNewFootTarget == true) {
      PVector distCheck    = PVector.sub(destination, position);
      float   distCheckMag = distCheck.mag();
      nodeMovementSpeed    = nodeMovementSpeedOrig;
      // print("distCheckMag: " + distCheckMag + "\n");

      if (distCheckMag <= 1.0) {
        // print("Foot reached new target...\n\n");
        nodeMovementSpeed = nodeMovementSpeedOrig;
        movementSpeed     = movementSpeedOrig;
        slowedDown        = false;
        spedUp            = false;
        footAtTarget      = true;
        destination = position.get();
        resetCollapsible();
        return;
      }
    }

    // For long moves, the closest node sometimes misses the target by more than 2; 
    // setting the distance check to 10 ensures that the conditions to terminate
    // the move trigger above
    if (dist < 10 && setNewFootTarget == false) {

      // Set the footDestination to be along the same vector, but at a distance greater than the 
      // current destination that is equal to the magnitude of the vector between the position
      // of the amoeba and the closestNode
      float   angleToFoot  = angleToNodeFromPosition(closestNode, true);
      // print("angleToFoot: " + angleToFoot + "\n");
      PVector distToFoot   = PVector.sub(closestNodeCopy, position); // represents translated position
      float   newDist      = distToFoot.mag() * newFootDestMagMultiplier;
      footDestination      = positionWith(angleToFoot, newDist);
      footDestination.add(position);
      setNewFootTarget     = true;

      if (debug) {
        noFill();
        strokeWeight(1);
        stroke(0, 255, 0);
        line(closestNodeCopy.x, closestNodeCopy.y, position.x, position.y);
      }

      // print("Setting new foot target with distance: " + newDist + "\n");
      // stopLoop = true;
    }

    // Only perform additional movements if the foot isn't at the target

    // Figure out how far we are from the amoeba's position - if it is greater than
    // 3 times the original radius, then slow down the movement speed of the leading node

    PVector distFromPosition = PVector.sub(position, closestNodeCopy);
    float   distPos = distFromPosition.mag();

    if (distPos > footTravelLimit && slowedDown == false) {
      nodeMovementSpeed = abs(nodeMovementSpeedOrig) * - 0.2;
      nodeMovementSpeed += nodeMovementSpeed;
      movementSpeed     += 0.03;
      // print("Slowing down leading node...\n");
      slowedDown = true;
      spedUp     = false;
    } 
    else if (distPos < footTooClose && spedUp == false) {
      nodeMovementSpeed = abs(nodeMovementSpeedOrig) * 4; 
      movementSpeed     = movementSpeedOrig;
      // print("Speeding up leading node... \n");
      spedUp     = true;
      slowedDown = false;
    } 
    else if (distPos > footTooClose && distPos < footTravelLimit && (spedUp == true || slowedDown == true)) {
      // The node is within normal range and either is going fast or slow..


      // Don't want to immediately return to default if it just slowed down
      // because it then will speed up again at normal speed and trigger a cycle of 
      // alternating between normal and slow. Therefore, use a threshold to make sure
      // that it remains slow for a little while
      if ((slowedDown && distPos < (footTravelLimit - footTolerance)) || spedUp) {
        nodeMovementSpeed = nodeMovementSpeedOrig; 
        movementSpeed     = movementSpeedOrig;
        // print("Speed returning to default...\n");
        spedUp     = false;
        slowedDown = false;
      }
    }





    PVector dirToMove = PVector.sub(footDestination, closestNodeCopy);
    dirToMove.normalize();
    dirToMove.mult(nodeMovementSpeed);
    closestNode.add(dirToMove);

    // Initialize these values
    int upIdx   = closestNodeIndex;
    int downIdx = closestNodeIndex;

    // Now handle the neighbor nodes
    for (int i=0; i < nodeChainLength; i++) {
      float speedToMove;
      if (i > 0) {
        speedToMove = (0.4/(i+1) * nodeMovementSpeed);
      } 
      else {
        speedToMove = 0.4 * nodeMovementSpeed;
      }

      // If we are accelerating the movement of the closest node, then we don't want
      // to add a speed factor to the chained nodes
      if (spedUp) {
        speedToMove = movementSpeed;
      }

      upIdx   = neighborNodeIndex(upIdx, true);      
      downIdx = neighborNodeIndex(downIdx, false);

      shiftNode(upIdx, i + 1, speedToMove, footDestination, true);
      shiftNode(downIdx, i + 1, speedToMove, footDestination, false);

      // This populates an ArrayList with values that we will use
      // to determine whether a node needs to retract towards the 
      // amoeba's position (because it is not affected by proximity
      // to the closest node)
      if (!collapsingIndicesSet) {
        indicesToCollapse.set(upIdx, false);
        indicesToCollapse.set(downIdx, false);
      }
    }

    // Mark the closestNode as not needing to collapse
    if (!collapsingIndicesSet) {
      indicesToCollapse.set(closestNodeIndex, false);
      collapsingIndicesSet = true;
    }

    // Now move the nodes that are supposed to collapse
    // towards the position of the amoeba

    for (int i = 0; i < indicesToCollapse.size();i++) {

      // Check whether this node is collapsible

      boolean collapsible = indicesToCollapse.get(i); 
      if (!collapsible) {
        continue;
      }

      // Get the relevant collapsing node
      PVector node = (PVector)expandedNodes.get(i);

      // Check how far it is from the amoeba position 
      // (always 0,0 in the transformed space)

      PVector localPos   = new PVector(0, 0);
      PVector distVector = PVector.sub(localPos, node);
      float   nodeDist   = distVector.mag();

      // Determine how far the node should be from the position of the amoeba

      PVector contractedNodePos = (PVector)contractedNodes.get(i);
      PVector proxDist          = PVector.sub(localPos, contractedNodePos);
      float   proximityToCenter = proxDist.mag();

      // Check whether the node is close enough to not need
      // to move any further

      if (abs(nodeDist - proximityToCenter) < 5) { 
        // Node is close enough, so mark it as not needing further updating
        indicesToCollapse.set(i, false);
        continue;
      }

      // The node still needs to contract towards the amoeba position.
      // Get distance and then get the vector from the contracted position that was
      // initialized for the node, and move the node towards that point

      PVector move = PVector.sub(contractedNodePos, node);
      move.normalize();

      // Some voodoo to make the node contract more quickly
      // than the movement of the amoeba, but not too quickly
      move.mult(nodeMovementSpeed/2 * (nodeDist*0.05));
      node.add(move);
    }

    // Random chance to move one of the collapsing nodes to a different position
    // TODO: Adjust to make enough movement so that it appears natural
    float r = random(100);
    if (r > 95) {
      repositionNonChainedLeg(false, 0, true);
    }
  }





  void shiftNode(int idx, int idxOffset, float speedToMove, PVector dest, boolean right) {
    // idx is the index of the node that should shift
    // idxOffset represents how far it is, in the array position, from the closestNode
    // idxOffset is used to determine what percentage of the magnitude of the vector from the closestNode
    // to the amoeba position will be used to set the movement vector for nodes that are too far
    // off angle from the closest node

    // Get a copy of the node to use in calculations
    PVector node     = (PVector)expandedNodes.get(idx);
    PVector nodeCopy = node.get();

    // Normalize it to the non-translated space
    nodeCopy.add(position.get());

    // Figure out how far away the leading node is from the position of the amoeba
    PVector leadingNode  = (PVector)expandedNodes.get(closestNodeIndex);
    float   leadingAngle = angleToNodeFromPosition(leadingNode, true);
    PVector distVector   = PVector.sub(leadingNode, new PVector(0, 0));
    float   dist         = distVector.mag();
    float   origDist     = dist;
    // How much to remove from the that distance to accommodate this node
    float subFactor      = (float)idxOffset / (nodeChainLength + 1);

    // If idxOffset is 1 and chain length is 3, then we will remove 1/4 of the dist
    // and set it as the dist for the node's target
    dist = dist - (dist * subFactor);

    float newDist = dist/origDist;
    float lenAdjust = newDist;

    float widthFactor = 0.3;
    if (expand)   widthFactor = 0.6;
    if (contract) widthFactor = 0.15;
    // Get the normal at that distance and offset
    PerpVectorPack pack = new PerpVectorPack(distVector, lenAdjust, (1-lenAdjust) * widthFactor, right);

    // Set the normal to be the nodeGoal
    PVector nodeGoal = pack.perpVectorPt();

    // Thresholds for lateral movement for chained nodes
    // Replacement for angle offset
    float rad = pack.perpVectorPtDistFromLine();

    float allowedMaxOffset = rad * 0.9;
    float allowedMinOffset = rad * 0.1;

    // Vector from the node's actual position to its goal position
    PVector vecFromNodeToExpectedPos = PVector.sub(nodeGoal, node);
    float   currentDist              = vecFromNodeToExpectedPos.mag();
    boolean moveFaster               = false;

    if (currentDist > allowedMaxOffset) {
      moveFaster = true;

      // Set the additive vector to move towards the goal
      nodeGoal.add(position.get());
    } 
    else if (currentDist < allowedMinOffset) {
      moveFaster = true;

      // New normal that is further from the orig vector
      PerpVectorPack newPack = new PerpVectorPack(distVector, lenAdjust, (1-lenAdjust) * 0.5, right);
      nodeGoal               = newPack.perpVectorPt();
      nodeGoal.add(position.get());
    } 
    else {
      // The node is in an acceptible position, move towards the destination
      moveFaster = false;
      nodeGoal    = dest.get();
    }

    if (debug) {
      if (moveFaster) {
        pushMatrix();
        noStroke();
        fill(0);
        ellipse(nodeGoal.x, nodeGoal.y, 5, 5);
        noFill();
        stroke(0);
        line(nodeCopy.x, nodeCopy.y, nodeGoal.x, nodeGoal.y);
        popMatrix();
      }
    }

    if (expand || contract) moveFaster = true;

    PVector dirToMove      = PVector.sub(nodeGoal, nodeCopy);
    float   nodeDistToDest = dirToMove.mag();
    dirToMove.normalize();

    if (moveFaster) {
      dirToMove.mult(speedToMove * chainedNodeFastSpeedMultiplier);
    } 
    else {
      dirToMove.mult(speedToMove);
    }

    node.add(dirToMove);
  }




  float angleToNodeFromPosition(PVector node, boolean translated) {
    // This ONLY works if they are in the same translated space
    // The position ALWAYS is 0,0 in the local space
    PVector pos;
    if (translated) {
      pos = new PVector(0, 0);
    } 
    else {
      pos = position.get();
    }
    float deltaX = node.x - pos.x;
    float deltaY = node.y - pos.y;

    float angleToNode = degrees(atan2(deltaY, deltaX)); 
    if (angleToNode < 0) {
      angleToNode = 360 + angleToNode;
    }
    return angleToNode;
  }





  int neighborNodeIndex(int idx, boolean up) {
    int offset;
    int upperLimit = expandedNodes.size();

    if (up) {
      offset = 1;
    } 
    else {
      offset = -1;
    }
    int newIndex = idx + offset;
    newIndex = newIndex % upperLimit;

    // Fix for how Processing handles modulo with numbers < 0
    if (newIndex < 0) {
      newIndex += upperLimit;
    }

    return newIndex;
  }





  void selectClosestNode() {

    float deltaX = destination.x - position.x;
    float deltaY = destination.y - position.y;

    float angle = degrees(atan2(deltaY, deltaX)); 
    if (angle < 0) {
      angle = 360 + angle;
    }

    int angleQuadrant;

    if (angle >=0 && angle < 90) {
      angleQuadrant = 1;
    } 
    else if (angle >= 90 && angle < 180) {
      angleQuadrant = 2;
    } 
    else if (angle >= 180 && angle < 270) {
      angleQuadrant = 3;
    } 
    else {
      angleQuadrant = 4;
    }

    float closest    = 9999;
    int closestIndex = -1;

    for (int i=0; i< expandedNodesAnglesQuadrants.size(); i++) {
      int a = expandedNodesAnglesQuadrants.get(i);
      if (a != angleQuadrant) {
        continue;
      }

      float aAngle = expandedNodesAngles.get(i);
      float dist = abs(aAngle - angle);
      if (dist < closest) {
        closest = dist;
        closestIndex = i;
      }
    }
    closestNodeIndex = closestIndex;
    closestNodeSelected = true;
  }





  void moveToRest() {
    boolean done = true;
    for (int i = 0; i < expandedNodes.size(); i++) {
      PVector nodePos = (PVector)expandedNodes.get(i);
      PVector basePos = (PVector)baseNodesForResting.get(i); 
      PVector diff    = PVector.sub(basePos, nodePos);
      float   magDiff = diff.mag();
      //print("nodePos: " + nodePos + ", basePos: " + basePos + ", magDiff: " + magDiff + "\n");
      // Don't need to move
      if (magDiff < (2)) {
        continue;
      }

      done = false;
      diff.normalize();
      diff.mult(nodeMovementSpeed);
      nodePos.add(diff);
    }

    if (done) {
      achievedRest = true;
    }
  }





  void moveToRandomRest() {
    // Chance for a leg to move a bit
    float r = random(100);
    if (r>98) {
      repositionNonChainedLeg(false, 0, false);
    }

    // Entire shape reconfigures
    float r2 = random(100);
    if (r2 > 99.9) {
      achievedRest = false;
      recalculateBaseNodesForResting();
    }
  }





  void repositionNonChainedLeg(boolean useIncomingIndex, int idx, boolean setContractedPosition) {
    int index;
    if (useIncomingIndex) {
      index = idx;
    } 
    else {
      index = (int)random(numBaseNodes);
    }

    boolean okToUse = indicesToCollapse.get(index);
    if (okToUse == false) {
      // increment index and recurse 
      int maxIndex = indicesToCollapse.size() - 1;
      if (index == maxIndex) {
        index = 0;
      } 
      else {

        index = randomUnchainedIndex();

        // TODO: This needs work - might set a chained node
        indicesToCollapse.set(index, true);
      }
      // print("index: " + index + " ");
      repositionNonChainedLeg(true, index, setContractedPosition);
      return;
    } 
    else {
      // Logic to move the selected node
      float thisAngle = baseNodesAngles.get(index);

      if (setContractedPosition == true) {
        // This should happen while the amoeba is moving

        float offset   = random(footTolerance);
        if (contract) {
          offset *= -1;
        } 
        else if (!expand) {
          float dirCheck = random(100);
          if (dirCheck < 50) offset *= -1;
        }


        float contractedLength = initialRadius + offset;
        contractedNodes.set(index, positionWith(thisAngle, contractedLength));
        indicesToCollapse.set(index, true);
      } 
      else {
        // This should happen when the amoeba is still
        float adj = random(footTolerance);
        if (random(100) > 50) {
          adj *= -1;
        }

        if (expand) adj   = abs(adj);
        if (contract) adj = -1 * abs(adj);

        float   len   = initialRadius + adj;
        PVector toAdd = positionWith(thisAngle, len);
        baseNodesForResting.set(index, toAdd);
        achievedRest = false;
      }
    }
  }





  int randomUnchainedIndex() {
    // Add the closestNodeIndex and the chained indices to an arraylist

    ArrayList<Integer> claimed = new ArrayList<Integer>();
    claimed.add(closestNodeIndex);
    int upIdx = closestNodeIndex;
    int dnIdx = closestNodeIndex;
    for (int i=0; i<nodeChainLength; i++) {
      upIdx   = neighborNodeIndex(upIdx, true);      
      dnIdx   = neighborNodeIndex(dnIdx, false);
      claimed.add(upIdx);
      claimed.add(dnIdx);
    }

    ArrayList<Integer> allIndices = new ArrayList<Integer>();
    for (int i=0; i < numBaseNodes; i++) {
      allIndices.add(i);
    }

    Set<Integer> claimedSet = new HashSet<Integer>(claimed);
    Set<Integer> allInd     = new HashSet<Integer>(allIndices);

    allInd.removeAll(claimedSet);

    List<Integer> goodNumbers = new ArrayList<Integer>(allInd);

    int ran = (int)random(goodNumbers.size());
    int selectedIdx = goodNumbers.get(ran);
    //print("claimed set: " + claimedSet + "\n");
    //print("selected idx: " + selectedIdx + "\n");
    return selectedIdx;
  }

  /* FORAGING */
  InteractiveObject findFood() {
    // Identify all consumables within radius, pick one to eat
    // Check for creatures && for Food objects -- TODO: creatures
    InteractiveObject food = world.closestFood(this.position, foodDetectionRadius * 0.5);
    return food;
  }





  /* DRAWING */
  void display() {
    pushMatrix();

    translate(position.x, position.y);
    drawBody();
    if (debug) {
      drawNodes();
      drawFoodDetectionRadius();
    }
    popMatrix();
  }





  void drawBody() {
    fill(180, 100);
    stroke(90, 100);

    if (debug) {
      if (contract) {
        fill(255, 0, 0, 100);
      } 
      else if (expand) {
        fill(0, 0, 255, 100);
      }
    }

    beginShape();
    // First control point
    PVector firstPt = (PVector)expandedNodes.get(0);
    curveVertex(firstPt.x, firstPt.y);

    for (int i = 0; i < expandedNodes.size(); i++) {
      PVector pt = (PVector)expandedNodes.get(i);
      curveVertex(pt.x, pt.y);
    }

    curveVertex(firstPt.x, firstPt.y);
    PVector secondPt = (PVector)expandedNodes.get(1);
    curveVertex(secondPt.x, secondPt.y);
    endShape();
  }





  void drawNodes() {
    popMatrix();

    fill(0, 0, 255);
    ellipse(destination.x, destination.y, 3, 3);
    fill(0, 255, 0);
    ellipse(position.x, position.y, 3, 3);

    pushMatrix();
    translate(position.x, position.y);

    fill(255, 0, 0, 100);
    noStroke();
    for (int i = 0; i < expandedNodes.size(); i++) {
      PVector node = (PVector)expandedNodes.get(i);
      ellipse(node.x, node.y, 2, 2);
    }
  }



  void drawFoodDetectionRadius() {
    popMatrix();
    stroke(50, 50);
    noFill();
    ellipse(position.x, position.y, foodDetectionRadius, foodDetectionRadius);
    pushMatrix();
    translate(position.x, position.y);
  }
}





/* STATE MACHINE STATES */
// Keep Amoeba specific classes in this tab

class AmoebaBrainStateForaging extends BrainState {
  PVector lastWayPoint;
  float   lastAngle;
  Amoeba  parentCreature;
  boolean lockedOntoFood;

  AmoebaBrainStateForaging(Creature c) {
    parentCreature = (Amoeba)c;
    name           = amoebaForaging;
    lockedOntoFood = false;
  }

  void doActions() {
    // if (debug) print("AmoebaBrainStateForaging doActions()\n");

    // Following waypoints, look for food in detection radius
    // If food is found, remove waypoints, tell the amoeba where the food is located
    // and set a condition to exit the foraging action and enter the attacking/eating action

    // Otherwise, check if still moving.
    // If not, then calculate a new waypoint, based on the previous,
    // and set the destination of the amoeba

    // Try to get a food target
    if (parentCreature.foodTarget == null) {
      parentCreature.foodTarget = parentCreature.findFood();
    }

    // If there is a food target and the amoeba isn't moving, we're on top of it
    if (parentCreature.foodTarget != null && !parentCreature.isMoving) {
      print("Amoeba arrived at food...\n");
      parentCreature.consume(parentCreature.foodTarget);
      parentCreature.currentFood += parentCreature.foodTarget.foodValue;
      print("Amoeba currentFood level: " + parentCreature.currentFood + "\n");
      parentCreature.foodTarget = null;
      lockedOntoFood = false;
      return;
    }

    if (parentCreature.foodTarget != null && lockedOntoFood == false) {
      // Set destination to food target 
      print("Found food for amoeba...\n");
      parentCreature.setDestination(parentCreature.foodTarget.position);
      lockedOntoFood = true;
      return;
    }

    if (!parentCreature.isMoving) {
      setWayPoint(lastAngle);
      parentCreature.setDestination(lastWayPoint.x, lastWayPoint.y);
      return;
    }
  }

  String checkConditions() {
    if (parentCreature.currentFood < parentCreature.foodMin) {
      return amoebaDying;
    }

    if (parentCreature.currentFood > parentCreature.hungerGoneThreshold) {
      return amoebaResting;
    }
    return "";
  }

  void entryActions() {
    print("Amoeba is entering foraging state...\n");
    parentCreature.brainActivity = "Foraging...\n";

    setWayPoint();
    parentCreature.setDestination(lastWayPoint.x, lastWayPoint.y);
  }

  void exitActions() {
    print("Amoeba is exiting foraging state...\n");
  }

  void setWayPoint() {
    lastAngle = random(360);
    setWayPoint(lastAngle);
  }

  void setWayPoint(float angle) {
    // Calculate a waypoint.
    // Angle should be within 45 degrees of the last angle

      float angleOffset  = random(45);
    lastAngle          = lastAngle + angleOffset;

    float initSize     = parentCreature.initialSize;
    float distanceMin  = initSize * 0.75;
    float distanceAdd  = random(distanceMin);
    float distance     = distanceMin + distanceAdd;

    lastWayPoint       = parentCreature.positionWith(lastAngle, distance);
    lastWayPoint.add(parentCreature.position.get());

    // If the waypoint is off of the screen, then create a new one with no angle bounds
    if (lastWayPoint.x < 0 || lastWayPoint.x > width || lastWayPoint.y < 0 || lastWayPoint.y > height ) {
      setWayPoint();
    }
  }
}





class AmoebaBrainStateResting extends BrainState {

  AmoebaBrainStateResting(Creature c) {
    parentCreature = (Amoeba)c;
    name = amoebaResting;
  }

  void doActions() {
    // if (debug) print("AmoebaBrainStateResting doActions()\n");
  }

  String checkConditions() {
    if (parentCreature.currentFood < parentCreature.hungerThreshold) {
      // Seek food
      return amoebaForaging;
    }
    return "";
  }

  void entryActions() {
    print("Amoeba is entering resting state...\n");
    parentCreature.brainActivity = "Resting...";
  }

  void exitActions() {
    print("Amoeba is exiting resting state...\n");
  }
}




class AmoebaBrainStateDying extends BrainState {

  AmoebaBrainStateDying(Creature c) {
    parentCreature = (Amoeba)c;
    name = amoebaDying;
  } 

  void doActions() {
    // Check death - Exit action of deallocating if dead.
  }

  void entryActions() {
    print("Amoeba is dying... ");
    parentCreature.die();
  }

  void exitActions() {
  }

  String checkConditions() {
    return "";
  }
}

