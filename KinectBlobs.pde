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

private Random random = new Random();

DeviceRegistry registry;

void spamCommand(PixelPusher p, PusherCommand pc) {
   for (int i=0; i<3; i++) {
    p.sendCommand(pc);
  }
}

class TestObserver implements Observer {
  public boolean hasStrips = false;
  public void update(Observable registry, Object updatedDevice) {
    println("Registry changed!");
    if (updatedDevice != null) {
      println("Device change: " + updatedDevice);
    }
    this.hasStrips = true;
  }
}

TestObserver testObserver;

void setup() {
  size(240, 8, P3D); // 5 tall for every strip
  registry = new DeviceRegistry();
  testObserver = new TestObserver();
  registry.addObserver(testObserver);
  frameRate(60);
  prepareExitHandler();
}

boolean tracking = false;
float lineSide = 1;
int followLead = 0;
int sign = 1;
boolean mouseMoved = false;

void mouseMoved()
{
  if (tracking) {
    followLead = width - mouseX;
    mouseMoved = true;
  }
//  println("mouse = (" + mouseX + ", " + mouseY + ")");
}

void mouseClicked()
{
  if (mouseButton == LEFT) {
    tracking = !tracking;
  } else {
    reset_blob();
  }
}

float mod_distance(float a, float b, float m)
{
  return abs(m / 2. - ((3 * m) / 2 + a - b) % m);
}

boolean first = true;

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
   
    if (!tracking) { 
      followLead++;
    }
    followLead = followLead % width;
    int numStrips = strips.size();
    if (numStrips == 0)
      return;
    
    mouse_blob();
    
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

