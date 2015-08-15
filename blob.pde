
final color[] kGoodBaseColors = { 
   #FF0000, #00FF00, #0000FF, #FFFF00, #FF00FF, #00FFFF,   
   #800000, #008000, #000080, #808000, #800080, #008080, #808080,  
   #C00000, #00C000, #0000C0, #C0C000, #C000C0, #00C0C0, #C0C0C0,  
   #600000, #006000, #000060, #606000, #600060, #006060, #606060,  
   #A00000, #00A000, #0000A0, #A0A000, #A000A0, #00A0A0, #A0A0A0,  
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

final float colorVariation = 30;
final float blobWidth = 12;
final float blobbiness = 14;
final float initialMotion = 0.03;
final float initialColorMotion = 3;

public class Blob
{
  public float x;
  public float y;
  
  private color baseColor;
  
  private Point2D[] blobPoints;  // offsets
  private color[] blobColors;
  private Point2D[] blobPointMotion;
  private color[] blobColorMotion;
  
  public Blob(float initialX) {
    x = initialX;
    y = height / 2;
    
    int subBlobs = 40;
    blobPoints = new Point2D[subBlobs];
    blobPointMotion = new Point2D[subBlobs];
    blobColors = new color[subBlobs];
    blobColorMotion = new color[subBlobs];
    
    baseColor = kGoodBaseColors[(int)random(0, kGoodBaseColors.length)];
//    while (red(baseColor) + green(baseColor) + blue(baseColor) < 40 ||
//           red(baseColor) + green(baseColor) + blue(baseColor) > 200) {
//      baseColor = color(random(0, 100), random(0, 100), random(0, 100));
//    }
    println("baseColor = " + red(baseColor) + ", "+green(baseColor)+", "+blue(baseColor));
    
    for (int i = 0; i < blobPoints.length; ++i) {
      float ellipseX = random(-blobbiness, blobbiness);
//      println("ellipseX = " + ellipseX);
      float ellipseY = random(-blobbiness / 4, blobbiness / 4);
      
      blobPoints[i] = new Point2D(ellipseX, ellipseY);
      blobPointMotion[i] = new Point2D(random(-initialMotion, initialMotion), 
                                       random(-initialMotion, initialMotion));
      
      float red = constrain(red(baseColor) + random(-colorVariation, colorVariation), 0, 100);
      float green = constrain(green(baseColor) + random(-colorVariation, colorVariation), 0, 100);
      float blue = constrain(blue(baseColor) + random(-colorVariation, colorVariation), 0, 100);
      
      println("sub blob color = " + red + ", "+green+", "+blue);      
      
      blobColors[i] = color(red, green, blue);
      blobColorMotion[i] = color(random(-initialColorMotion, initialColorMotion), 
                                 random(-initialColorMotion, initialColorMotion), 
                                 random(-initialColorMotion, initialColorMotion));    
    }
  }
  
  private float subBlobDistance(int i)
  {
    Point2D sub = blobPoints[i];
    return sqrt((sub.x * sub.x + sub.y * sub.y));
  }
  
  private float subBlobColorDistance(int i)
  {
    color subColor = blobColors[i];
    return sqrt((red(baseColor) - red(subColor)) * (red(baseColor) - red(subColor)) +
                (green(baseColor) - green(subColor)) * (green(baseColor) - green(subColor)) +
                (blue(baseColor) - blue(subColor)) * (blue(baseColor) - blue(subColor)));
  }
  
  public void draw()
  {
    noStroke();
    for (int i = 0; i < blobPoints.length; ++i) {
      Point2D sub = blobPoints[i];
      
      color c = blobColors[i];
      
      float distance = subBlobDistance(i);
      float alpha = 60 * (1 - distance / blobWidth);
      
      fill(red(c), green(c), blue(c), alpha);
//      println("c = " + red(c) + ", "+green(c)+", "+blue(c) + ", " + alpha);
//      println("Filling ellipse at " + (x+sub.x) + ", " + (y+sub.y));
      ellipse(x + sub.x, y + sub.y, 6, 6);
    }    
  }
  
  public void drift()
  {
    for (int i = 0; i < blobPoints.length; ++i) {
      // Drift position of sub blobs
      {
        Point2D sub = blobPoints[i];
        float distance = subBlobDistance(i);
        // pull towards center proportional to distance so sub blobs don't escape
        blobPointMotion[i].x += -blobPoints[i].x * distance * 0.0001;
        blobPointMotion[i].y += -blobPoints[i].y * distance * 0.0001;
        blobPoints[i].x += blobPointMotion[i].x;
        blobPoints[i].y += blobPointMotion[i].y;
      }
      
      // Drift color of sub blobs
      {
        color sub = blobColors[i];
        float distance = subBlobColorDistance(i);
        // pull towards center proportional to distance so sub blobs don't escape
        float redMotion = red(blobColorMotion[i]) + (red(baseColor) - red(blobColors[i])) * distance * 0.1;
        float greenMotion = green(blobColorMotion[i]) + (green(baseColor) - green(blobColors[i])) * distance * 0.1;
        float blueMotion = blue(blobColorMotion[i]) + (blue(baseColor) - blue(blobColors[i])) * distance * 0.1;
        
//        float red = constrain(red(blobColors[i]) + red(blobColorMotion[i]), 0, 100); 
//        float green = constrain(green(blobColors[i]) + green(blobColorMotion[i]), 0, 100);
//        float blue = constrain(blue(blobColors[i]) + blue(blobColorMotion[i]), 0, 100);
//        
//        blobColors[i] = color(red, green, blue);
      }
    }
  }
}

Blob[] blobs = null;

void reset_blob()
{
  blobs = new Blob[1];
  blobs[0] = new Blob(followLead);
}

void mouse_blob()
{
  blendMode(BLEND);
  colorMode(RGB, 100);
  if (blobs == null) {
    reset_blob();
  }
  
  blobs[0].draw();
  blobs[0].drift();
  blobs[0].x = followLead;
  
  blendMode(SUBTRACT);
  fill(2, 2, 2, 100);
  rect(0, 0, width, height);
  
//  if (mouseMoved) {
//    blob_centered_at(followLead);
//    mouseMoved = false;
//  }
}

