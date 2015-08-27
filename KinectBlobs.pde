 /*
 * Generate a colour cycle on a PixelPusher array.
 * Won't do anything until a PixelPusher is detected.
 */

import com.heroicrobot.dropbit.registry.*;
import com.heroicrobot.dropbit.devices.pixelpusher.Pixel;
import com.heroicrobot.dropbit.devices.pixelpusher.Strip;
import com.heroicrobot.dropbit.devices.pixelpusher.PixelPusher;
import com.heroicrobot.dropbit.devices.pixelpusher.PusherCommand;

import java.util.*;

DeviceRegistry registry;

class TestObserver implements Observer {
  public boolean hasStrips = false;
  public void update(Observable registry, Object updatedDevice) {
    //println("Registry changed!");
    if (updatedDevice != null) {
      //println("Device change: " + updatedDevice);
    }
    this.hasStrips = true;
  }
}

boolean kTestMode = false;

TestObserver testObserver;
BlobManager blobManager;
PFont font;
int fontSize = 11;

void setup() {
  size(240, 8, P3D);
  registry = new DeviceRegistry();
  registry.setLogging(false);
  testObserver = new TestObserver();
  registry.addObserver(testObserver);
  frameRate(60);
  prepareExitHandler();
  
  blobManager = new BlobManager();
  
  font = createFont("Leelawadee", fontSize, false);
  // Latha, Consolas
  textFont(font, fontSize);
}

//float mod_distance(float a, float b, float m)
//{
//  return abs(m / 2. - ((3 * m) / 2 + a - b) % m);
//}

boolean first = true;

int timeBlobsLastSeen = -1;
int timeTextStarted = -1;
float textHue = 0;
int textMode = -1;
float textX = 30;
float textDirection = 0.4;

void drawText()
{
  blendMode(BLEND);
  int timeSinceText = millis() - timeTextStarted;
  float fadeInAlpha = 100 * (timeSinceText < 3000 ? timeSinceText / 3000.0 : 1.0);
  
  if (textMode == 0) {
    colorMode(HSB, 100);
    fill(textHue, 100, fadeInAlpha);
    text("M O A R", width / 2 - 20 + 90 * sin(millis() / 1000.0), height);
    
  } else if (textMode == 1) {
    colorMode(HSB, 100);
    fill(textHue, 100, fadeInAlpha);
    pushMatrix();
    translate(width / 2, height / 2);
    scale(0.8 + 2 * (1 + sin(millis() / 1000.0)));
    text("M O A R", -20, height / 2);
    popMatrix();
    
  } else if (textMode == 2) {
    colorMode(HSB, 100);
    fill(textHue, 100, fadeInAlpha);
    pushMatrix();
    translate(textX, height / 2);
    rotate(millis() / 500.0);
    text("M O A R", -16, height / 2);
    popMatrix();
    textX += textDirection;
    if ((textDirection > 0 && textX > 210) || (textDirection < 0 && textX < 30)) {
      textDirection *= -1;
    }
  }
  //else if (textMode == 3) {
  //  int counter = (int)(millis() / 10.0);
    
  //  colorMode(HSB, 100);
  //  for (int y = 0; y < height; ++y) {
  //    for (int x = 0; x < width; ++x) {
  //      stroke((11 * x + counter) % 100, 100, 50 * (1 + sin(x / 10.0 + millis() / 500.0)));
  //      point(x, y);
  //    }
  //  }
    
  //  colorMode(RGB, 100);
  //  fill(100, 0, 0, fadeInAlpha);
  //  text("M O A R", width / 2 - 20, height);
  //}
  
  textHue += 0.2;
  if (textHue >= 100) {
    textHue = 0;
  }
}

void draw()
{
  if (testObserver.hasStrips) {   
    registry.startPushing();
    registry.setExtraDelay(0);
    registry.setAutoThrottle(true);
    registry.setAntiLog(true);    
    List<Strip> strips = registry.getStrips();
   
   if (first) {
      background(0, 0, 0);
      first = false;
   }
   
    int numStrips = strips.size();
    if (numStrips == 0)
      return;
    
    blobManager.update();
    
    if (blobManager.hasBlobs()) {
      timeBlobsLastSeen = millis();
      timeTextStarted = -1;
      textMode = -1;
    } else if (kTestMode || timeBlobsLastSeen != -1) {
      int timeSinceBlobs = millis() - timeBlobsLastSeen;
      if (timeSinceBlobs > (kTestMode ? 2000 : 30000)) {
        if (textMode == -1) {
          textMode = (int)random(0, 3);
        }
        if (timeTextStarted == -1) {
          timeTextStarted = millis();
        }
        drawText();
      }
    }
    
    int fadeRate = (blobManager.hasBlobs() ? 2 : 20);
    
    // Fade out the old blobs
    colorMode(RGB, 100);
    blendMode(SUBTRACT);
    fill(fadeRate, fadeRate, fadeRate, 100);
    rect(0, 0, width, height);
        
    // Render the scene
    int x=0;
    int y=0;
    int stripy = 0;
    int yscale = height / strips.size();
    for (Strip strip : strips) {
      int xscale = width / strip.getLength();
      for (int stripx = 0; stripx < strip.getLength(); stripx++) {
        x = stripx * xscale;
        y = stripy * yscale; 
        color c = get(x, y);

        strip.setPixel(c, stripx);
      }
      stripy++;
    }
  }
}

private void prepareExitHandler () {

  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {

    public void run () {

      System.out.println("Shutdown hook running");

      List<Strip> strips = registry.getStrips();
      for (Strip strip : strips) {
        for (int i=0; i<strip.getLength(); i++)
          strip.setPixel(#000000, i);
      }
      for (int i=0; i<100000; i++)
        Thread.yield();
    }
  }
  ));
}