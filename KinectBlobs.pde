
import com.heroicrobot.dropbit.registry.*;
import com.heroicrobot.dropbit.devices.pixelpusher.Pixel;
import com.heroicrobot.dropbit.devices.pixelpusher.Strip;
import com.heroicrobot.dropbit.devices.pixelpusher.PixelPusher;

import java.util.*;

import KinectPV2.*;

//PGraphics pg;

DeviceRegistry registry;
TestObserver testObserver;

KinectPV2 kinect;
BlobManager blobManager;

class TestObserver implements Observer {
  public boolean hasStrips = false;
  public void update(Observable registry, Object updatedDevice) {
    //println("Registry changed!");
    if (updatedDevice != null) {
      println("Device change: " + updatedDevice);
    }
    this.hasStrips = true;
  }
}

void setup()
{
  //size(1536, 440, P3D);
  size(240, 8, P3D);
  frameRate(60);
  
  // Init pixelpusher
  registry = new DeviceRegistry();
  registry.setLogging(false);
  testObserver = new TestObserver();
  registry.addObserver(testObserver);
 
 // Init Kinect
  kinect = new KinectPV2(this);   
  //kinect.enableDepthImg(true);   
  kinect.enableSkeletonDepthMap(true);
  //kinect.enableSkeleton3DMap(true);
  kinect.enableBodyTrackImg(true);
  //kinect.enableInfraredImg(true);
  kinect.init();
 
  prepareExitHandler();
  
  blobManager = new BlobManager(kinect);
  
  //pg = createGraphics(blobsRegionWidth, blobsRegionHeight);
}

boolean first = true;

int timeBlobsLastSeen = -1;
int blobsXOffset = 0;
int blobsYOffset = 0;//430;
int blobsRegionHeight = 8;
int blobsRegionWidth = 240;//512;

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
    
    //blendMode(BLEND);
    //colorMode(RGB, 100);
    
    //fill(0);
    //stroke(0);
    //rect(0, 0, width, height - blobsRegionHeight);
    
    //image(kinect.getDepthImage(), 0, 0);
    //image(kinect.getInfraredImage(), 512*2, 0);

    //PImage bodyImage = kinect.getBodyTrackImage();
    //bodyImage.filter(INVERT);
    //bodyImage.filter(DILATE);
    //image(bodyImage, 512, 0);
    
    //fill(100, 0, 0);
    //stroke(100, 0, 0);
    //text(String.format("fps: %.1f", frameRate), 10, 15);
    //blendMode(ADD);
    
    //pg.beginDraw();
    //pg.background(0, 0, 0);
    //translate(blobsRegionWidth / 2, blobsRegionHeight / 2);
    //scale(0.5, 1.5);
    //translate(-blobsRegionWidth / 2, -blobsRegionHeight / 2);
    //image(bodyImage, 0, 0, blobsRegionWidth, blobsRegionHeight);
    //image(bodyImage, blobsXOffset, blobsYOffset, blobsRegionWidth, blobsRegionHeight);
    //pg.endDraw();
    //image(pg, blobsXOffset, blobsYOffset, blobsRegionWidth, blobsRegionHeight);
       
    int numStrips = strips.size();
    if (numStrips == 0)
      return;
    
    //translate(0, blobsYOffset);
    blobManager.update();
    //translate(0, -blobsYOffset);
        
    if (blobManager.hasBlobs()) {
        timeBlobsLastSeen = millis();
    }
    
    // Fade out the old blobs
    colorMode(RGB, 100);
    blendMode(SUBTRACT);
    int fadeRate = (blobManager.hasBlobs() || (millis() - timeBlobsLastSeen < 2000) ? 2 : 20);
    fill(fadeRate, fadeRate, fadeRate, 100);
    rect(blobsXOffset, blobsYOffset, blobsRegionWidth, blobsRegionHeight);
    
    // Render the scene
    int x=0;
    int y=0;
    int stripy = 0;
    int yscale = blobsRegionHeight / strips.size();
    for (Strip strip : strips) {
     int xscale = blobsRegionWidth / strip.getLength();
     for (int stripx = 0; stripx < strip.getLength(); stripx++) {
       x = stripx * xscale + blobsXOffset;
       y = stripy * yscale + blobsYOffset; 
       color c = get(x, y);
       strip.setPixel(c, stripx);
     }
     stripy++;
    }
  }
}

public PVector coordsForJoint(KJoint joint)
{
  return new PVector(joint.getX() / 512.0 * width, joint.getY() / 424 * height);
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