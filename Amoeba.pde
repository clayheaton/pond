class Amoeba extends Creature {
  float size;
  int initialSize     = 70;
  float initialRadius = initialSize   * 0.5;
  float footTolerance = initialRadius * 0.5;

  PVector   position;
  PVector   destination;

  int       numBaseNodes    = 18;
  int       maxNodes        = 20;
  int       nodeChainLength = 2;

  float     baseAngleSpacing;
  float     angleSpacing;

  // Protected as references
  ArrayList baseNodes;
  ArrayList baseNodesAngles;
  ArrayList contractedNodes;

  // Used during execution
  ArrayList expandedNodes;
  ArrayList<Float> expandedNodesAngles;
  ArrayList<Integer>expandedNodesAnglesQuadrants;
  ArrayList<Boolean> indicesToCollapse; 

  int       closestNodeIndex;
  boolean   closestNodeSelected;

  boolean   isMoving;
  boolean   hasFoodTarget;
  boolean   footAtTarget;

  boolean   achievedRest;

  boolean   collapsingIndicesSet;

  float     movementSpeed     = 0.06;
  float     nodeMovementSpeed = 0.1;

  Amoeba(float x, float y) {
    isMoving            = false;
    position            = new PVector(x, y);
    destination         = new PVector(x, y);

    baseNodes           = new ArrayList();
    baseNodesAngles     = new ArrayList();
    contractedNodes     = new ArrayList();
    expandedNodes       = new ArrayList();
    expandedNodesAngles = new ArrayList<Float>();
    expandedNodesAnglesQuadrants = new ArrayList<Integer>();
    indicesToCollapse   = new ArrayList<Boolean>();

    size = initialSize;
    closestNodeIndex    = 0; // Initialize to avoid error
    closestNodeSelected = false;

    achievedRest        = true;

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

      baseNodes.add(positionWith(thisAngle, len));
      expandedNodes.add(positionWith(thisAngle, len));

      // Determine the contracted nodes (for parts of the amoeba that must shrink)
      float contractedLength = initialRadius - random(footTolerance);
      contractedNodes.add(positionWith(thisAngle, contractedLength));

      // Initialize all to true
      indicesToCollapse.add(true);
    }
  }

  void setDestination(float x, float y) {
    destination.x = x;
    destination.y = y;
    isMoving             = true;
    closestNodeSelected  = false;
    footAtTarget         = false;
    collapsingIndicesSet = false;
    achievedRest         = false;

    // Reset the indices
    for (int i = 0; i < numBaseNodes; i++) {
      indicesToCollapse.set(i, true);
    }
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
        
        // Pick a new variation on the baseNodes
        
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

    PVector distVect = PVector.sub(destination, closestNodeCopy);
    float dist = distVect.mag();

    // Stop moving if the closest foot is close enough to the destination.
    // This needs to change when the amoeba has a food target.

    if (dist < 2) {
      footAtTarget = true;

      // TEMP MEASURE - When foot is at target, then move destination to current position
      destination = position.get();
    }

    // Only perform additional movements if the foot isn't at the target

      PVector dirToMove = PVector.sub(destination, closestNodeCopy);
    dirToMove.normalize();
    dirToMove.mult(nodeMovementSpeed);
    closestNode.add(dirToMove);

    // Initialize these values
    int upIdx   = closestNodeIndex;
    int downIdx = closestNodeIndex;

    // Now handle the neighbor nodes
    for (int i=0; i < nodeChainLength; i++) {
      float factor;
      if (i > 0) {
        factor = 0.4/(i+1);
      } 
      else {
        factor = 0.4;
      }

      upIdx   = neighborNodeIndex(upIdx, true);      
      downIdx = neighborNodeIndex(downIdx, false);

      shiftNode(upIdx, factor, destination);
      shiftNode(downIdx, factor, destination);

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

      if (nodeDist <= proximityToCenter) { 
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
  }

  void shiftNode(int idx, float velocityAdjustment, PVector dest) {

    PVector node = (PVector)expandedNodes.get(idx);
    PVector nodeCopy = node.get();
    nodeCopy.add(position.get());

    // Check the angle between this point at the leading foot.
    // If it is too large, then set the destination as leading node
    // instead of the amoeba's destination. This will prevent feet from
    // growing wider than they should be

    PVector leadingNode  = (PVector)expandedNodes.get(closestNodeIndex);
    float   nodeAngle    = angleToNodeFromPosition(node);
    float   leadingAngle = angleToNodeFromPosition(leadingNode);
    float   deltaAngle   = abs(nodeAngle - leadingAngle);
    //print("deltaAngle: " + deltaAngle + "\n");

    PVector actualDest;

    // Uncertain how much this helps
    // the point was to prevent adjacent nodes from creating 
    // large angles between each other if they are the consecutive
    // leading nodes for movement directives

    if (deltaAngle > 2.0) {
      actualDest = position.get();
    } 
    else {
      actualDest = dest.get();
    }

    PVector dirToMove = PVector.sub(actualDest, nodeCopy);
    dirToMove.normalize();
    dirToMove.mult(nodeMovementSpeed * velocityAdjustment);
    node.add(dirToMove);
  }

  float angleToNodeFromPosition(PVector node) {
    float deltaX = node.x - position.x;
    float deltaY = node.y - position.y;

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
    // print("angleQuadrant: " + angleQuadrant + "\n");

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


    /* LEGACY IMPLEMENTATION BASED ON DISTANCE 
     // Initialize to a large size
     float dist = width * 99;
     
     for (int i=0; i < expandedNodes.size(); i++) {
     PVector nodePos = ((PVector)expandedNodes.get(i)).get(); // have to copy the PVector
     // Normalize the node positions to the coordinate space
     nodePos.add(position.get());
     
     PVector diff = PVector.sub(destination, nodePos);
     float thisDist = diff.mag();
     if (thisDist < dist) {
     // Candidate for closest node
     dist = thisDist;
     closestNodeIndex = i;
     }
     //print("Node index: " + i + ", thisDist: " + thisDist + ", nodePos: " + nodePos + ", closestNodeIndex: " + closestNodeIndex + "\n");
     }
     closestNodeSelected = true;
     //print("closestNodeIndex: " + closestNodeIndex);
     */
  }
  
  void moveToRest() {
    boolean done = true;
    for (int i = 0; i < expandedNodes.size(); i++) {
     PVector nodePos = (PVector)expandedNodes.get(i);
     PVector basePos = (PVector)baseNodes.get(i); 
     PVector diff    = PVector.sub(basePos,nodePos);
     float   magDiff = diff.mag();
     //print("nodePos: " + nodePos + ", basePos: " + basePos + ", magDiff: " + magDiff + "\n");
     // Don't need to move
     if (magDiff < (footTolerance)) {
      continue; 
     }
     
     done = false;
     diff.normalize();
     diff.mult(nodeMovementSpeed);
     nodePos.add(diff);
     
    }
    
    if(done) {
     achievedRest = true; 
    }
    
  }
  
  void moveToRandomRest() {
    
  }

  void display() {
    pushMatrix();

    translate(position.x, position.y);
    drawBody();
    // drawNodes();
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
    fill(255, 0, 0, 100);
    noStroke();
    for (int i = 0; i < expandedNodes.size(); i++) {
      PVector node = (PVector)expandedNodes.get(i);
      ellipse(node.x, node.y, 2, 2);
    }
  }
}

