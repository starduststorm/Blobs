
final color[] kGoodBaseColors = { 
   #FF0000, #00FF00, #0000FF, #FFFF00, #FF00FF, #00FFFF,   
   #808000, #800080, #008080, #808080,  
   #C00000, #00C000, #0000C0, #C0C000, #C000C0, #00C0C0, #C0C0C0,  
   #606000, #600060, #006060, #606060, 
   #A0A000, #A000A0, #00A0A0, #A0A0A0,  
   #E00000, #00E000, #0000E0, #E0E000, #E000E0, #00E0E0, #E0E0E0,
};

final int kSmoothingFactor = 10;

final float colorVariation = 40;
final float blobWidth = 12;
final float blobbiness = 14;
final float initialMotion = 0.03;

public class Blob implements GestureDelegate
{
  private float x;
  private LinkedList<Float> xVelocities;
  public float y;
  
  private color baseColor;
  
  private PVector[] blobPVectors;  // offsets
  private color[] blobColors;
  private PVector[] blobPVectorMotion;
  
  public int lastSeen;
  
  boolean leftHandOut;
  boolean rightHandOut;
  
  boolean leftFootOut;
  boolean rightFootOut;

  private ArrayList<Blobby> blobbies;
  
  int birthdate;
  
  GestureRecognizer gestureRecognizer; 
  boolean visualDebug;
  boolean superBlobbies;
  
  public Blob()
  {
    birthdate = millis();
    
    x = -1;
    y = blobsRegionHeight / 2;
    xVelocities = new LinkedList<Float>();
    
    int subBlobs = (int)random(7, 40);
    blobPVectors = new PVector[subBlobs];
    blobPVectorMotion = new PVector[subBlobs];
    blobColors = new color[subBlobs];
    //blobColorMotion = new color[subBlobs];
    
    blobbies = new ArrayList<Blobby>();
    
    baseColor = kGoodBaseColors[(int)random(0, kGoodBaseColors.length)];
//    while (red(baseColor) + green(baseColor) + blue(baseColor) < 40 ||
//           red(baseColor) + green(baseColor) + blue(baseColor) > 200) {
//      baseColor = color(random(0, 100), random(0, 100), random(0, 100));
//    }
    
    for (int i = 0; i < blobPVectors.length; ++i) {
      float ellipseX = random(-blobbiness, blobbiness);
//      println("ellipseX = " + ellipseX);
      float ellipseY = random(-blobbiness / 4, blobbiness / 4);
      
      blobPVectors[i] = new PVector(ellipseX, ellipseY);
      blobPVectorMotion[i] = new PVector(random(-initialMotion, initialMotion), 
                                       random(-initialMotion, initialMotion));
      
      float red = 0, green = 0, blue = 0;
      while (red + blue + green < 0xA0) {
        red = constrain(red(baseColor) + random(-colorVariation, colorVariation), 0, 100);
        green = constrain(green(baseColor) + random(-colorVariation, colorVariation), 0, 100);
        blue = constrain(blue(baseColor) + random(-colorVariation, colorVariation), 0, 100);
      }
            
      blobColors[i] = color(red, green, blue);
    }
    
    gestureRecognizer = new GestureRecognizer(this);
  }
  
  public float _tweakY(float y)
  {
    // It's kind of hard to reach the top and bottom of the frame, so magnify it a bit. 
    return (y - height / 2.0) * 1.5 + height / 2.0 + 1;
  }
  
  boolean armed()
  {
    // you must be at least 1 second old to own a firearm (pending NRA lawsuit to lower it to time of conception)
    // this cuts down on explosions due to sensor noise when a blob first enters the frame.
    return (millis() - birthdate > 1000);
  }
  
  public void updateWithSkeleton(KSkeleton skeleton)
  {
    gestureRecognizer.updateWithSkeleton(skeleton);
    
    KJoint[] joints = skeleton.getJoints();
    //KJoint neck = joints[KinectPV2.JointType_SpineShoulder];
    KJoint leftShoulder = joints[KinectPV2.JointType_ShoulderLeft];
    KJoint rightShoulder = joints[KinectPV2.JointType_ShoulderRight];
    KJoint leftHand = joints[KinectPV2.JointType_HandLeft];
    KJoint rightHand = joints[KinectPV2.JointType_HandRight];
    KJoint leftHip = joints[KinectPV2.JointType_HipLeft];
    KJoint rightHip = joints[KinectPV2.JointType_HipRight];
    
    //final float kHandThreshold = 20;
    //final float kPixelPointTweak = 1.0;
    
    //PVector neckPx = coordsForJoint(neck);
    PVector leftShoulderPx = coordsForJoint(leftShoulder);
    PVector rightShoulderPx = coordsForJoint(rightShoulder);
    PVector rightHandPx = coordsForJoint(rightHand);
    PVector leftHandPx = coordsForJoint(leftHand);
    
    rightHandPx.y = this._tweakY(rightHandPx.y);
    leftHandPx.y = this._tweakY(leftHandPx.y);
    
    //float leftHandDistance = (leftShoulderPx.x - leftHandPx.x);
    //float rightHandDistance = -(rightShoulderPx.x - rightHandPx.x);
    
    PVector leftShoulderPt = new PVector(leftShoulder.getX(), leftShoulder.getY(), leftShoulder.getZ());
    PVector rightShoulderPt = new PVector(rightShoulder.getX(), rightShoulder.getY(), rightShoulder.getZ());
    PVector leftHandPt = new PVector(leftHand.getX(), leftHand.getY(), leftHand.getZ());
    PVector rightHandPt = new PVector(rightHand.getX(), rightHand.getY(), rightHand.getZ());
    PVector leftHipPt = new PVector(leftHip.getX(), leftHip.getY(), leftHip.getZ());
    PVector rightHipPt = new PVector(rightHip.getX(), rightHip.getY(), rightHip.getZ());
    
    final float kHandShoulderThreshold = 50;
    final float kHandHipThreshold = 20.0; // Don't shoot blobbies when hands are resting at sides
    final float kPixelPointTweak = 4.0;
    float leftHandDistance = leftShoulderPt.dist(leftHandPt);
    float rightHandDistance = rightShoulderPt.dist(rightHandPt);
    
    boolean leftHandOut = leftHandDistance > kHandShoulderThreshold + (this.leftHandOut ? -2.0 : 0.0)
                          && leftHipPt.dist(leftHandPt) > kHandHipThreshold;
    if ((this.superBlobbies || this.leftHandOut == false) && leftHandOut == true) {
      shootBlobby(leftHandPx.y, -2.0);
    }
    this.leftHandOut = leftHandOut;
    
    boolean rightHandOut = rightHandDistance > kHandShoulderThreshold + (this.rightHandOut ? -2.0 : 0.0)
                           && rightHipPt.dist(rightHandPt) > kHandHipThreshold;
    if ((this.superBlobbies || this.rightHandOut == false) && rightHandOut == true) {
      shootBlobby(rightHandPx.y, 2.0);
    }
    this.rightHandOut = rightHandOut;
    
    KJoint spineBase = joints[KinectPV2.JointType_SpineBase];
    PVector spineBasePx = coordsForJoint(spineBase);
    
    PVector leftFootPx = coordsForJoint(joints[KinectPV2.JointType_FootLeft]);
    PVector rightFootPx = coordsForJoint(joints[KinectPV2.JointType_FootRight]);
    
    final float footWaveThreshold = 21.0;
    
    float leftFootXDistance = spineBasePx.x - leftFootPx.x;
    boolean leftFootOut = (leftFootXDistance > footWaveThreshold + (this.leftFootOut ? -2.0 : 0.0));
    if (this.leftFootOut == false && leftFootOut == true) {
      shootSplody(-2.0);
    }
    this.leftFootOut = leftFootOut;

    float rightFootXDistance = rightFootPx.x - spineBasePx.x; 
    boolean rightFootOut = (rightFootXDistance > footWaveThreshold + (this.rightFootOut ? -2.0 : 0.0));
    if (this.rightFootOut == false && rightFootOut == true) {
      shootSplody(2.0);
    }
    this.rightFootOut = rightFootOut;
    
    if (visualDebug) {
      blendMode(BLEND);
      colorMode(RGB, 100);
      
      color handsColor = #00FF00;
      
      // Draw a hand blobby bounds display
      noFill();
      stroke(handsColor);
      float leftLineX = leftShoulderPx.x - kHandShoulderThreshold / kPixelPointTweak;
      float rightLineX = rightShoulderPx.x + kHandShoulderThreshold / kPixelPointTweak;
      rect(leftLineX, -1, rightLineX - leftLineX, blobsRegionHeight + 2);
      
      noStroke();
      fill(handsColor);
      
      // Draw the positions of the hands, regarding the blobby thresholds
      ellipse(leftShoulderPx.x - leftHandDistance / kPixelPointTweak, leftHandPx.y, 2, 2);
      ellipse(rightShoulderPx.x + rightHandDistance / kPixelPointTweak, rightHandPx.y, 2, 2);
      
      color footsColor = #0000FF;
      
      // Draw a foot blobby bounds display
      stroke(footsColor);
      noFill();
      rect(spineBasePx.x - footWaveThreshold, -1, 2 * footWaveThreshold, blobsRegionHeight + 2);
      
      // Draw the positions of the feet
      noStroke();
      fill(footsColor);
      ellipse(leftFootPx.x, leftFootPx.y, 2, 2);
      ellipse(rightFootPx.x, rightFootPx.y, 2, 2);
      
      // Draw lines for expected heights of head and spinebase
      KJoint head = joints[KinectPV2.JointType_Head];
      PVector headPx = coordsForJoint(head);
      
      final float kGraceThreshold = 0.4;
      final float kIdealSpineBase = 5.4;
      final float kIdealHead = 3.4;
      
      float spineDistance = spineBasePx.y - kIdealSpineBase;
      float headDistance = headPx.y - kIdealHead;
      //println("headDistance = ", headDistance, ", spineDistance = ", spineDistance);
      if (abs(spineDistance) > kGraceThreshold || abs(headDistance) > kGraceThreshold) {
        float spineRedness = abs(spineDistance) > kGraceThreshold ? (abs(spineDistance) - kGraceThreshold) * 100 : 0.0;
        float headRedness = abs(headDistance) > kGraceThreshold ? (abs(headDistance) - kGraceThreshold) * 100 : 0.0;
        stroke(min(100, spineRedness + headRedness), 0, 0);
        float lineY = (spineDistance + headDistance > 0 ? blobsRegionHeight : 1);
        line(spineBasePx.x - 8, lineY, spineBasePx.x + 8, lineY);
      }
      
      /*
      spineBasePx = [ 159.19864, 5.6104956, 0.0 ]
headPx = [ 164.18872, 3.3198502, 0.0 ]

// about right:
headPx = [ 155.64514, 3.4524684, 0.0 ]
spineBasePx = [ 151.42424, 5.3664484, 0.0 ]

// too close 
headPx = [ 185.27417, 2.907837, 0.0 ]
spineBasePx = [ 176.16768, 6.6047373, 0.0 ]


pointed too high:
spineBasePx = [ 157.84882, 7.7996635, 0.0 ]
headPx = [ 160.55844, 5.5222387, 0.0 ]
*/
    }
  }
  
  void checkCollisionWithFlamingos(LinkedList<Flamingo> flamingos)
  {
    for (Flamingo f : flamingos) {
      for (Blobby b : blobbies) {
        if (f.collidesWithBlobby(b)) {
          f.impactWithBlobby(b);
          break;
        }
      }
    }
  }
  
  private int _indexOfOutermostSubBlob(boolean left)
  {
    int index = -1;
    float outerMost = -1;
    for (int i = 0; i < blobPVectors.length; ++i) {
      PVector sub = blobPVectors[i];
      if (index == -1 || (left && sub.x < outerMost) || (!left && sub.x > outerMost)) {
        outerMost = sub.x;
        index = i;
      }
    }
    return index;
  }
  
  private void _shootBlobbyLike(float y, float initialdx, BlobbyType blobbyType)
  {
    if (!armed()) {
      return;
    }
    int index = _indexOfOutermostSubBlob(initialdx < 0);
    if (index != -1) {
      color outerColor = blobColors[index];
      float blobbyDimming = 0.5;
      color blobbyColor = color(blobbyDimming * red(outerColor), blobbyDimming * green(outerColor), blobbyDimming * blue(outerColor));
      
      PVector startPVector = new PVector(x + blobPVectors[index].x, this._tweakY(y));
      
      Blobby blobby = new Blobby(startPVector, new PVector(initialdx, 0.0), blobbyColor, blobbyType);
      blobbies.add(blobby);
    }
  }
  
  private void shootBlobby(float y, float initialdx)
  {
    _shootBlobbyLike(y, initialdx, BlobbyType.Blobby);
  }
  
  private void shootLiney(float y, float initialdx)
  {
    _shootBlobbyLike(y, initialdx, BlobbyType.Liney);
  }
  
  private void shootSplody(float initialdx)
  {
    if (!armed()) {
      return;
    }
    int index = _indexOfOutermostSubBlob(initialdx < 0);
    if (index != -1) {
      for (int i = 0; i < 20; ++i) {
        color blobbyColor = blobColors[(int)random(0, (int)blobColors.length)];
        PVector start = new PVector(x + blobPVectors[index].x, blobsRegionHeight / 2.0 + random(-2, 2));
        PVector startVelocity = new PVector(initialdx + random(-0.5, 0.5), random(-1, 2));
        Blobby blobby = new Blobby(start, startVelocity, blobbyColor, BlobbyType.Splody);
        blobbies.add(blobby);
      }
    }
  }
  
  public float getX()
  {
    return x;
  }
  
  public void setX(float newX)
  {
    if (x != -1) {
      xVelocities.add(newX - x);
      if (xVelocities.size() > kSmoothingFactor) {
        xVelocities.removeFirst();
      }
    }
    x = newX;
  }
  
  public float smoothedVelocity()
  {    float smoothedVelocity = 0;
    if (xVelocities.size() > 0) {
      for (Float f : xVelocities) {
        smoothedVelocity += f;
      }
      smoothedVelocity /= xVelocities.size();
    }
    return smoothedVelocity;
  }
  
  public void coast()
  {
    //println("Coasting blob " + this + " at " + smoothedVelocity);
    //setX(x + smoothedVelocity);
    x += this.smoothedVelocity();
  }
  
  private float subBlobDistance(int i)
  {
    PVector sub = blobPVectors[i];
    return sqrt((sub.x * sub.x + sub.y * sub.y));
  }
  
  public void draw()
  {
    drift();
    
    blendMode(BLEND);
    colorMode(RGB, 100);
    
    noStroke();
    for (int i = 0; i < blobPVectors.length; ++i) {
      PVector sub = blobPVectors[i];
      
      color c = blobColors[i];
      
      int age = millis() - birthdate;
      float youngAlphaFactor = (age < 3000 ? (age / 3000.0) : 1);
      
      float distance = subBlobDistance(i);
      float alpha = 60 * (1 - distance / blobWidth) * youngAlphaFactor;
      
      fill(red(c), green(c), blue(c), alpha);
      //println("c = " + red(c) + ", "+green(c)+", "+blue(c) + ", " + alpha);
      //println("Filling ellipse at " + (x+sub.x) + ", " + (y+sub.y));
      if (!this.visualDebug) {
        ellipse(x + sub.x, y + sub.y, 6, 6);
      }
    }
    
    for (int i = blobbies.size() - 1; i >= 0; --i) {
      Blobby b = blobbies.get(i);
      if (b.isDead()) {
        blobbies.remove(i);
      }
      b.update();
      b.draw();
    }
  }
  
  private void drift()
  {
    // Shift the subblobs around to make the colors move
    for (int i = 0; i < blobPVectors.length; ++i) {
      // Drift position of sub blobs
      {
        //PVector sub = blobPVectors[i];
        float distance = subBlobDistance(i);
        // pull towards center proportional to distance so sub blobs don't escape
        blobPVectorMotion[i].x += -blobPVectors[i].x * distance * 0.0001;
        blobPVectorMotion[i].y += -blobPVectors[i].y * distance * 0.0001;
        blobPVectors[i].x += blobPVectorMotion[i].x;
        blobPVectors[i].y += blobPVectorMotion[i].y;
      }
    }
  }
  
  // Gestures
  
  public void setVisualDebug(boolean visualDebug)
  {
    this.visualDebug = visualDebug;
  }
  
  public void setSuperBlobbies(boolean superBlobbies)
  {
    this.superBlobbies = superBlobbies;
  }
}


/*
KinectPV2.JointType_Head
KinectPV2.JointType_Neck
KinectPV2.JointType_SpineShoulder
KinectPV2.JointType_SpineMid
KinectPV2.JointType_SpineBase

KinectPV2.JointType_ShoulderRight
KinectPV2.JointType_ElbowRight
KinectPV2.JointType_WristRight
KinectPV2.JointType_HandRight
KinectPV2.JointType_HandTipRight
KinectPV2.JointType_ThumbRight

KinectPV2.JointType_ShoulderLeft
KinectPV2.JointType_ElbowLeft
KinectPV2.JointType_WristLeft
KinectPV2.JointType_HandLeft
KinectPV2.JointType_HandTipLeft
KinectPV2.JointType_ThumbLeft

KinectPV2.JointType_HipRight
KinectPV2.JointType_KneeRight
KinectPV2.JointType_AnkleRight
KinectPV2.JointType_FootRight

KinectPV2.JointType_HipLeft
KinectPV2.JointType_KneeLeft
KinectPV2.JointType_AnkleLeft
KinectPV2.JointType_FootLeft
*/