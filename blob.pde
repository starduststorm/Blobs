
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

public class Blob
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
  
  private ArrayList<Blobby> blobbies;
  
  int birthdate;
  
  public Blob() {
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
    //println("baseColor = " + red(baseColor) + ", "+green(baseColor)+", "+blue(baseColor));
    
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
  }
  
  public float _tweakY(float y)
  {
    // It's kind hard to reach the top and bottom of the frame, so magnify it a bit. 
    return (y - height / 2.0) * 1.5 + height / 2.0 + 1;
  }
  
  public void updateWithSkeleton(KSkeleton skeleton)
  {
    KJoint[] joints = skeleton.getJoints();
    //KJoint neck = joints[KinectPV2.JointType_SpineShoulder];
    KJoint leftShoulder = joints[KinectPV2.JointType_ShoulderLeft];
    KJoint rightShoulder = joints[KinectPV2.JointType_ShoulderRight];
    //if (neck.isTracked()) {
    KJoint leftHand = joints[KinectPV2.JointType_HandLeft];
    KJoint rightHand = joints[KinectPV2.JointType_HandRight];
    
    //final float kHandThreshold = 20;
    //final float kPixelPointTweak = 1.0;
    
    //PVector neckPx = coordsForJoint(neck);
    PVector leftShoulderPx = coordsForJoint(leftShoulder);
    PVector rightShoulderPx = coordsForJoint(rightShoulder);
    PVector rightHandPx = coordsForJoint(rightHand);
    PVector leftHandPx = coordsForJoint(leftHand);
    
    println("rightHandPx = " + rightHandPx);
    println("leftHandPx = " + leftHandPx);
    
    rightHandPx.y = this._tweakY(rightHandPx.y);
    leftHandPx.y = this._tweakY(leftHandPx.y);
    
    //float leftHandDistance = (leftShoulderPx.x - leftHandPx.x);
    //float rightHandDistance = -(rightShoulderPx.x - rightHandPx.x);
    
    PVector leftShoulderPt = new PVector(leftShoulder.getX(), leftShoulder.getY(), leftShoulder.getZ());
    PVector rightShoulderPt = new PVector(rightShoulder.getX(), rightShoulder.getY(), rightShoulder.getZ());
    PVector rightHandPt = new PVector(rightHand.getX(), rightHand.getY(), rightHand.getZ());
    PVector leftHandPt = new PVector(leftHand.getX(), leftHand.getY(), leftHand.getZ());
    
    final float kHandThreshold = 50;
    final float kPixelPointTweak = 4.0;
    float leftHandDistance = leftShoulderPt.dist(leftHandPt);
    float rightHandDistance = rightShoulderPt.dist(rightHandPt);
    //println("leftHandDistance = " + leftHandDistance);
    //println("rightHandDistance = " + rightHandDistance);

    // 
    
    boolean leftHandOut = leftHandDistance > kHandThreshold;
    if (this.leftHandOut == false && leftHandOut == true) {
      shootBlobby(leftHandPx.y, -2.0);
    }
    this.leftHandOut = leftHandOut;
    
    boolean rightHandOut = rightHandDistance > kHandThreshold;
    if (this.rightHandOut == false && rightHandOut == true) {
      shootBlobby(rightHandPx.y, 2.0);
    }
    this.rightHandOut = rightHandOut;
    
    
    if (visualDebug) {
      blendMode(BLEND);
      colorMode(RGB, 100);
      stroke(#FF0000);
      //noFill(); // fill the threshold ellipse, since it suppresses the blob from being all fadey
      //ellipse(neckPx.x, neckPx.y, kHandThreshold / kPixelPointTweak * 2.0, kHandThreshold / kPixelPointTweak * 2.0);
      float leftLineX = leftShoulderPx.x - kHandThreshold / kPixelPointTweak;
      line(leftLineX, 0, leftLineX, height);
      float rightLineX = rightShoulderPx.x + kHandThreshold / kPixelPointTweak;
      line(rightLineX, 0, rightLineX, height);
      noStroke();
      fill(#00FF00);
      ellipse(leftShoulderPx.x - leftHandDistance / kPixelPointTweak, leftHandPx.y, 2, 2);
      ellipse(rightShoulderPx.x + rightHandDistance / kPixelPointTweak, rightHandPx.y, 2, 2);
    }
  }
  
  private void shootBlobby(float y, float initialdx)
  {
    float outerMost = -1;
    color outerColor = #000000;
    for (int i = 0; i < blobPVectors.length; ++i) {
      PVector sub = blobPVectors[i];
      if (outerMost == -1 || (initialdx < 0 && sub.x < outerMost) || (initialdx > 0 && sub.x > outerMost)) {
        outerMost = sub.x;
        outerColor = blobColors[i];
      }
    }
    if (outerMost != -1) {
      float blobbyDimming = 0.5;
      color blobbyColor = color(blobbyDimming * red(outerColor), blobbyDimming * green(outerColor), blobbyDimming * blue(outerColor));
      
      PVector startPVector = new PVector(x + outerMost, this._tweakY(y));
      
      Blobby blobby = new Blobby(startPVector, blobbyColor, initialdx);
      blobbies.add(blobby);
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
      ellipse(x + sub.x, y + sub.y, 6, 6);
    }
    
    for (int i = blobbies.size() - 1; i >= 0; --i) {
      Blobby b = blobbies.get(i);
      if (b.x < 0 || b.x > blobsRegionWidth) {
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
}