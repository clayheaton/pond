import java.util.*;

class Amoeba extends Creature {
  float size;
  int   initialSize     = 70;
  float initialRadius   = initialSize   * 0.5;
  float footTolerance   = initialRadius * 0.5;
  float footTravelLimit = initialSize   * 2.0;
  float footTooClose    = initialSize   * 0.75;

  int       angleTolerance = 45;

  PVector   position;
  PVector   destination;
  PVector   footDestination;

  int       numBaseNodes    = 18;
  int       maxNodes        = 20;
  int       nodeChainLength = 3;

  float     baseAngleSpacing;
  float     angleSpacing;

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

  float     movementSpeed     = 0.06;
  float     nodeMovementSpeed = 0.1;

  // Copies of the originals that we can revert to after speed changes
  float     movementSpeedOrig     = movementSpeed;
  float     nodeMovementSpeedOrig = nodeMovementSpeed;

  boolean   slowedDown;
  boolean   spedUp;

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

    initializeNodes();
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
    performMove();
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
      float   newDist      = distToFoot.mag() * 2.75;
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

      shiftNode(upIdx, i + 1, speedToMove, footDestination);
      shiftNode(downIdx, i + 1, speedToMove, footDestination);

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

  // idx is the index of the node that should shift
  // idxOffset represents how far it is, in the array position, from the closestNode
  // idxOffset is used to determine what percentage of the magnitude of the vector from the closestNode
  // to the amoeba position will be used to set the movement vector for nodes that are too far
  // off angle from the closest node

    void shiftNode(int idx, int idxOffset, float speedToMove, PVector dest) {

    PVector node = (PVector)expandedNodes.get(idx);
    PVector nodeCopy = node.get();
    nodeCopy.add(position.get());

    // Check the angle between this point at the leading foot.
    // If it is too large, then set the destination as leading node
    // instead of the amoeba's destination. This will prevent feet from
    // growing wider than they should be

    PVector leadingNode  = (PVector)expandedNodes.get(closestNodeIndex);
    float   nodeAngle    = angleToNodeFromPosition(node, true);
    float   leadingAngle = angleToNodeFromPosition(leadingNode, true);
    float   deltaAngle   = abs(nodeAngle - leadingAngle);
    //print("deltaAngle: " + deltaAngle + "\n");

    PVector actualDest;

    // Uncertain how much this helps
    // the point was to prevent adjacent nodes from creating 
    // large angles between each other if they are the consecutive
    // leading nodes for movement directives

    boolean useAltSpeed = false;

    // TODO: Better approach is not to check the angle, but to check distance from a registration
    // point that is offset from the vector connecting the amoeba's position to the location
    // of the node closest to the destination

    if (deltaAngle > angleTolerance) {
      //print("node at idx: " + idx + " is out of angle range with range: " + deltaAngle + "\n");
      //print("leading angle: " + leadingAngle + "\n");
      PVector distVector = PVector.sub(leadingNode, new PVector(0, 0));
      float   dist = distVector.mag();

      // How much to remove from the dist
      float subFactor = (float)idxOffset / (nodeChainLength + 1);

      //print("idxOffset/(nodeChainLength + 1): " + idxOffset + "/" + (nodeChainLength+1) + " = " + subFactor + "\n");

      // If idxOffset is 1 and chain length is 3, then we will remove 1/4 of the dist
      // and set it as the dist for the target to correct the angle
      //print("subFactor: " + subFactor + ", dist: " + dist + ", ");

      dist = dist - (dist * subFactor);
      //print("new dist: " + dist + "\n\n");
      // Distance needs to be a fraction of the leading node distance
      PVector correctedVector = positionWith(leadingAngle, dist);

      actualDest = correctedVector;
      actualDest.add(position.get());

      if (debug) {
        noStroke();
        fill(255, 0, 0);
        ellipse(actualDest.x, actualDest.y, 5, 5);
        stroke(0, 0, 255);
        noFill();
        strokeWeight(1);
        PVector testV = leadingNode.get();
        testV.add(position.get());
        line(testV.x, testV.y, position.x, position.y);
      }

      //stopLoop = true;

      useAltSpeed = true;
    } 
    else {
      actualDest = dest.get();
    }

    PVector dirToMove = PVector.sub(actualDest, nodeCopy);
    float nodeDistToDest = dirToMove.mag();
    dirToMove.normalize();


    if (useAltSpeed) {
      dirToMove.mult(nodeMovementSpeed/(2 * (nodeDistToDest*0.05))); // TODO: Balance
      //print("angle adjusting\n");
    } 
    else {
      dirToMove.mult(speedToMove);
    }

    node.add(dirToMove);
  }

  // This ONLY works if they are in the same translated space
  // The position ALWAYS is 0,0 in the local space
  float angleToNodeFromPosition(PVector node, boolean translated) {
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
        float contractedLength = initialRadius - random(footTolerance);
        contractedNodes.set(index, positionWith(thisAngle, contractedLength));
        indicesToCollapse.set(index, true);
      } 
      else {
        // This should happen when the amoeba is still
        float adj = random(footTolerance);
        if (random(100) > 50) {
          adj *= -1;
        }

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
    for (int i=0; i < numBaseNodes; i++){
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

  void display() {
    pushMatrix();

    translate(position.x, position.y);
    drawBody();
    if (debug) {
      drawNodes();
    }
    popMatrix();
  }

  void drawBody() {
    fill(180, 100);
    stroke(90, 100);

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
}

