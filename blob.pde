
final color[] kGoodBaseColors = { 
   #FF0000, #00FF00, #0000FF, #FFFF00, #FF00FF, #00FFFF,   
   #808000, #800080, #008080, #808080,  
   #C00000, #00C000, #0000C0, #C0C000, #C000C0, #00C0C0, #C0C0C0,  
   #606000, #600060, #006060, #606060, 
   #A0A000, #A000A0, #00A0A0, #A0A0A0,  
   #E00000, #00E000, #0000E0, #E0E000, #E000E0, #00E0E0, #E0E0E0,  
};

private class Point2D
{
  public float x;
  public float y;
  public Point2D(float x, float y) {
    this.x = x;
    this.y = y;
  }
}

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
  
  private Point2D[] blobPoints;  // offsets
  private color[] blobColors;
  private Point2D[] blobPointMotion;
  
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
    blobPoints = new Point2D[subBlobs];
    blobPointMotion = new Point2D[subBlobs];
    blobColors = new color[subBlobs];
    //blobColorMotion = new color[subBlobs];
    
    blobbies = new ArrayList<Blobby>();
    
    baseColor = kGoodBaseColors[(int)random(0, kGoodBaseColors.length)];
//    while (red(baseColor) + green(baseColor) + blue(baseColor) < 40 ||
//           red(baseColor) + green(baseColor) + blue(baseColor) > 200) {
//      baseColor = color(random(0, 100), random(0, 100), random(0, 100));
//    }
    //println("baseColor = " + red(baseColor) + ", "+green(baseColor)+", "+blue(baseColor));
    
    for (int i = 0; i < blobPoints.length; ++i) {
      float ellipseX = random(-blobbiness, blobbiness);
//      println("ellipseX = " + ellipseX);
      float ellipseY = random(-blobbiness / 4, blobbiness / 4);
      
      blobPoints[i] = new Point2D(ellipseX, ellipseY);
      blobPointMotion[i] = new Point2D(random(-initialMotion, initialMotion), 
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
  
  public void setLeftHandOut(boolean leftHandOut)
  {
    if (this.leftHandOut == false && leftHandOut == true) {
      shootBlobby(true);
    }
    this.leftHandOut = leftHandOut;
}
  
  public void setRightHandOut(boolean rightHandOut)
  {
    if (this.rightHandOut == false && rightHandOut == true) {
      shootBlobby(false);
    }
    this.rightHandOut = rightHandOut;
  }
  
  private void shootBlobby(boolean left)
  {
    float outerMost = -1;
    color outerColor = #000000;
    for (int i = 0; i < blobPoints.length; ++i) {
      Point2D sub = blobPoints[i];
      if (outerMost == -1 || (left && sub.x < outerMost) || (!left && sub.x > outerMost)) {
        outerMost = sub.x;
        outerColor = blobColors[i];
      }
    }
    if (outerMost != -1) {
      float blobbyDimming = 0.5;
      color blobbyColor = color(blobbyDimming * red(outerColor), blobbyDimming * green(outerColor), blobbyDimming * blue(outerColor));
      Blobby blobby = new Blobby(x + outerMost, blobbyColor, (left ? -2 : 2));
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
    Point2D sub = blobPoints[i];
    return sqrt((sub.x * sub.x + sub.y * sub.y));
  }
  
  public void draw()
  {
    drift();
    
    blendMode(BLEND);
    colorMode(RGB, 100);
    noStroke();
    for (int i = 0; i < blobPoints.length; ++i) {
      Point2D sub = blobPoints[i];
      
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
    for (int i = 0; i < blobPoints.length; ++i) {
      // Drift position of sub blobs
      {
        //Point2D sub = blobPoints[i];
        float distance = subBlobDistance(i);
        // pull towards center proportional to distance so sub blobs don't escape
        blobPointMotion[i].x += -blobPoints[i].x * distance * 0.0001;
        blobPointMotion[i].y += -blobPoints[i].y * distance * 0.0001;
        blobPoints[i].x += blobPointMotion[i].x;
        blobPoints[i].y += blobPointMotion[i].y;
      }
    }
  }
}