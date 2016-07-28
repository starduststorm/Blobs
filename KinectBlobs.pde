
import com.heroicrobot.dropbit.registry.*;
import com.heroicrobot.dropbit.devices.pixelpusher.Pixel;
import com.heroicrobot.dropbit.devices.pixelpusher.Strip;
import com.heroicrobot.dropbit.devices.pixelpusher.PixelPusher;

import java.util.*;

import KinectPV2.*;

DeviceRegistry registry;
TestObserver testObserver;

KinectPV2 kinect;
BlobManager blobManager;
SpectrumAnalyzer spectrum;
BitsPattern bitsPattern;

boolean first = true;

int timeBlobsLastSeen = -1;
int timeBlobsFirstSeen = -1;

final int displayHeight = 8;
final int displayWidth = 240;

final int blobsOriginY = 16;
final int blobsOriginX = 0;
final int blobsRegionHeight = displayHeight;
final int blobsRegionWidth = displayWidth;

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
  size(240, 24, P3D);
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
  
  textSize(8);
  
  spectrum = new SpectrumAnalyzer(this);
  bitsPattern = new BitsPattern();
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
    
    blendMode(BLEND);
    colorMode(RGB, 100);
    fill(0, 0, 0);
    noStroke();
    rect(0, 0, displayWidth, displayHeight);
    
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
    
    // Fade out the previous frame
    translate(blobsOriginX, blobsOriginY);
    colorMode(RGB, 100);
    blendMode(SUBTRACT);
    int fadeRate = 2;
    fill(fadeRate, fadeRate, fadeRate, 100);
    noStroke();
    rect(0, 0, blobsRegionWidth, blobsRegionHeight);
    blobManager.update();
    translate(-blobsOriginX, -blobsOriginY);
    
    // Copy blobs pixels into the display
    blendMode(BLEND);
    copy(blobsOriginX, blobsOriginY, blobsRegionWidth, blobsRegionHeight, 0, 0, displayWidth, displayHeight);
       
    if (blobManager.hasBlobs()) {
      if (millis() - timeBlobsLastSeen > 100) {
        timeBlobsFirstSeen = millis();
      }
      timeBlobsLastSeen = millis();
    }
    
    // Background display
    
    // fade wave in and out with blobs
    float blobsAlphaLimiter;
    float timeSinceBlobAppearance = millis() - timeBlobsFirstSeen;
    float timeSinceLastBlob = millis() - timeBlobsLastSeen;
    if (timeSinceLastBlob > 100) {
      blobsAlphaLimiter = min(1.0, max(0.1, (timeSinceLastBlob - 100) / 5000));
    } else {
      blobsAlphaLimiter = max(0.15, 1.0 - timeSinceBlobAppearance / 2500);
    }
    
    spectrum.drawWithAlphaMultiplier(blobsAlphaLimiter);
    
    boolean makeNewBits = millis() > 2000 && !blobManager.hasBlobs() && !spectrum.isWaveformDisplayed();
    bitsPattern.update(makeNewBits);
    bitsPattern.draw();
    
    renderRegionToStrand(0, 0, displayWidth, displayHeight);
  }
}

public void renderRegionToStrand(int regionStartX, int regionStartY, int regionWidth, int regionHeight)
{
  List<Strip> strips = registry.getStrips();
  int x=0;
  int y=0;
  int stripy = 0;
  int yscale = regionHeight / strips.size();
  for (Strip strip : strips) {
   int xscale = regionWidth / strip.getLength();
   for (int stripx = 0; stripx < strip.getLength(); stripx++) {
     x = stripx * xscale + regionStartX;
     y = stripy * yscale + regionStartY; 
     color c = get(x, y);
     strip.setPixel(c, stripx);
   }
   stripy++;
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