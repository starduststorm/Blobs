
import com.heroicrobot.dropbit.registry.*;
import com.heroicrobot.dropbit.devices.pixelpusher.Pixel;
import com.heroicrobot.dropbit.devices.pixelpusher.Strip;
import com.heroicrobot.dropbit.devices.pixelpusher.PixelPusher;

import java.util.*;

final boolean useKinect = true;
import KinectPV2.*;

final boolean useSpectrum = false;

final boolean showCameras = false;

final boolean mountRtL = true; // banner mounted right-to-left

DeviceRegistry registry;
TestObserver testObserver;

KinectPV2 kinect;
BlobManager blobManager;

Random rand = new Random();
PaletteManager palettes;

ArrayList<IdlePattern> idlePatterns;
IdlePattern activeIdlePattern = null;
IdlePattern lastIdlePattern = null;

SpectrumAnalyzer spectrum = null;

boolean first = true;

int timeBlobsLastSeen = -1;
int timeBlobsFirstSeen = -1;

final int displayHeight = 8;
final int displayWidth = 236;

final int blobsOriginY = 16;
final int blobsOriginX = 0;
final int blobsRegionHeight = displayHeight;
final int blobsRegionWidth = displayWidth;

class TestObserver implements Observer {
  public boolean hasStrips = false;
  Object device;
  public void update(Observable registry, Object updatedDevice) {
    //println("Registry changed!");
    if (updatedDevice != null && device == null) {
      println("Device change: " + updatedDevice);
    }
    device = updatedDevice;
    this.hasStrips = true;
  }
}

void settings()
{
  int w,h;
  if (showCameras) {
    w = 1536; h = 440;
  } else {
    w = displayWidth; h = 24;
  }
  size(w, h, P3D);
}

void setup()
{
  frameRate(60);
  
  // Init pixelpusher
  registry = new DeviceRegistry();
  registry.setLogging(false);
  testObserver = new TestObserver();
  registry.addObserver(testObserver);

 if (useKinect) {
   // Init Kinect
    kinect = new KinectPV2(this);   
    kinect.enableSkeletonDepthMap(true);
    //kinect.enableSkeleton3DMap(true);
    if (showCameras) {
      kinect.enableBodyTrackImg(true);
      kinect.enableInfraredImg(true);
      kinect.enableDepthImg(true);
    }
    kinect.init();
 }
 
  palettes = new PaletteManager();
 
  prepareExitHandler();
  
  blobManager = new BlobManager(kinect);
  
  textSize(8);
  
  idlePatterns = new ArrayList<IdlePattern>();
  
  // FIXME: this is crashing on dev mac, 100% of the time now but 0% earlier. port leak or something?
  if (useSpectrum) {
    spectrum = new SpectrumAnalyzer(displayWidth, displayHeight, this);
    idlePatterns.add(spectrum);
  }
  idlePatterns.add(new BitsPattern(displayWidth, displayHeight));
  
  FlamingoPattern flamingoPattern = new FlamingoPattern(displayWidth, displayHeight);
  idlePatterns.add(flamingoPattern);
  blobManager.flamingoPattern = flamingoPattern;
  
  //idlePatterns.add(new TextBanner(displayWidth, displayHeight));
}

void draw()
{
  int currentMillis = millis();
  
  // FIXME: move these to setup()?
  registry.startPushing();
  registry.setExtraDelay(0);
  registry.setAutoThrottle(true);
  registry.setAntiLog(true);    
  
  if (first) {
     background(0, 0, 0);
     first = false;
  }

  
  blendMode(BLEND);
  colorMode(RGB, 100);
  
    PVector depthImageLoc = new PVector(0, 4*blobsRegionHeight);

  if (showCameras) {
    pushStyle();
    fill(0);
    stroke(0);
    rect(0, depthImageLoc.y, width, height - depthImageLoc.y);
  
    image(kinect.getDepthImage(), depthImageLoc.x, depthImageLoc.y);
    image(kinect.getInfraredImage(), 512*2, 2*blobsRegionHeight);

    PImage bodyImage = kinect.getBodyTrackImage();
    bodyImage.filter(INVERT);
    bodyImage.filter(DILATE);
    image(bodyImage, 512, 0);
    popStyle();
  }
  
  if (frameCount %100 == 0) {
    println("Framerate: " + frameRate);
  }
  
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
  //image(bodyImage, blobsOriginX, blobsOriginY, blobsRegionWidth, blobsRegionHeight);
  //pg.endDraw();
  //image(pg, blobsOriginX, blobsOriginY, blobsRegionWidth, blobsRegionHeight);
  
  // Fade out the previous frame
  translate(blobsOriginX, blobsOriginY);
  colorMode(RGB, 100);
  blendMode(SUBTRACT);
  int fadeRate = 7;
  fill(fadeRate, fadeRate, fadeRate, 100);
  noStroke();
  rect(0, 0, blobsRegionWidth, blobsRegionHeight);
  if (useKinect) {
    blobManager.update();
    
    ArrayList<KSkeleton> skeletons = kinect.getSkeletonDepthMap();
    pushMatrix();
    translate(depthImageLoc.x, depthImageLoc.y);
    for (KSkeleton skel : skeletons) {
      DrawSkeleton(skel);
    }
    popMatrix();
  }
  
  translate(-blobsOriginX, -blobsOriginY);
  
  // Copy blobs pixels into the display
  blendMode(BLEND);
  copy(blobsOriginX, blobsOriginY, blobsRegionWidth, blobsRegionHeight, 0, 0, displayWidth, displayHeight);
     
  if (blobManager.hasBlobs()) {
    if (currentMillis - timeBlobsLastSeen > 100) {
      timeBlobsFirstSeen = currentMillis;
    }
    timeBlobsLastSeen = currentMillis;
  }
  
  boolean runSpectrum = useSpectrum && spectrum.wantsToRun();
  if (runSpectrum && !blobManager.hasBlobs() && !spectrum.isRunning() && !spectrum.isStopping()) {
    if (activeIdlePattern != null) {
      activeIdlePattern.lazyStop();
      activeIdlePattern = null;
    }
    spectrum.startPattern();
  }
  if (spectrum.isRunning() || spectrum.isStopping()) {
    // FIXME: this is crashing on dev mac, 100% of the time now but 0% earlier. port leak or something?
    spectrum.update();
  }
  
  // Start patterns a second after we stop tracking someone
  if (currentMillis - timeBlobsLastSeen > 1000) {
    for (IdlePattern pattern : idlePatterns) {
      if (pattern.isRunning()) {
        pattern.stopInteraction();
      }
    }
    
    if (activeIdlePattern == null && !spectrum.isRunning()) {
      int choice = (int)random(idlePatterns.size());
      IdlePattern idlePattern = idlePatterns.get(choice);
      if (idlePattern != lastIdlePattern && !idlePattern.isRunning() && !idlePattern.isStopping() && idlePattern.wantsToRun()) {
        idlePattern.startPattern();
        activeIdlePattern = idlePattern;
        lastIdlePattern = idlePattern;
      }
    }
  }
  
  blendMode(BLEND);
  noTint();
  
  // Update or stop patterns
  for (IdlePattern pattern : idlePatterns) {
    if (blobManager.hasBlobs() && pattern.isRunning() && !pattern.isInteracting()) {
      if (pattern.wantsInteraction()) {
        pattern.startInteraction();
      } else {
        println("Idle stopping pattern due to blobs...");
        // null out idle patterns when *stopping* can do cross-transition from pattern to pattern bettter
        activeIdlePattern = null;
        pattern.lazyStop();
        if (useSpectrum && spectrum.isRunning()) {
          spectrum.lazyStop();
        }
      }
    }
    
    if (pattern.isRunning() || pattern.isStopping()) {
      pattern.update();
    } else {
      pattern.idleUpdate();
    }
  }
  
  // clear out idle patterns that have stopped themselves
  if (activeIdlePattern != null && !activeIdlePattern.isRunning()) {
    activeIdlePattern = null;
  }
  
  // time out idle patterns after some minutes
  final int kIdlePatternTimeout = 1000 * 60 * 3;
  if (activeIdlePattern != null && activeIdlePattern.isRunning() && millis() - activeIdlePattern.startMillis > kIdlePatternTimeout) {
    if (activeIdlePattern.wantsToIdleStop()) {
      activeIdlePattern.lazyStop();
      activeIdlePattern = null;
    }
  }
  
  
  renderRegionToStrand(0, 0, displayWidth, displayHeight);
}

public void renderRegionToStrand(int regionStartX, int regionStartY, int regionWidth, int regionHeight)
{
  List<Strip> strips = registry.getStrips();
  if (strips.size() == 0) {
    return;
  }
  colorMode(RGB, 100);
  int x=0;
  int y=0;
  int stripy = 0;
  int yscale = regionHeight / strips.size();
  for (Strip strip : strips) {
   int xscale = regionWidth / strip.getLength();
   for (int stripx = 0; stripx < strip.getLength(); stripx++) {
     if (mountRtL) {
       x = blobsRegionWidth - (stripx * xscale + regionStartX) - 1;
     } else {
       x = stripx * xscale + regionStartX;
     }
     y = stripy * yscale + regionStartY; 
     color c = get(x, y);
     c = color(red(c), blue(c), green(c)); // notorious
     strip.setPixel(c, stripx);
   }
   stripy++;
  }
}

public PVector coordsForJoint(KJoint joint)
{
  return new PVector(joint.getX() / 512.0 * displayWidth, joint.getY() / 424 * displayHeight);
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

//DRAW BODY
 void DrawSkeleton(KSkeleton skeleton) {
  KJoint[] joints = skeleton.getJoints();

//draw different color for each hand state
  drawHandState(joints[KinectPV2.JointType_HandRight]);
  drawHandState(joints[KinectPV2.JointType_HandLeft]);

  color col  = skeleton.getIndexColor();
  fill(col);
  stroke(col);

  drawBone(joints, KinectPV2.JointType_Head, KinectPV2.JointType_Neck);
  drawBone(joints, KinectPV2.JointType_Neck, KinectPV2.JointType_SpineShoulder);
  drawBone(joints, KinectPV2.JointType_SpineShoulder, KinectPV2.JointType_SpineMid);
  drawBone(joints, KinectPV2.JointType_SpineMid, KinectPV2.JointType_SpineBase);
  drawBone(joints, KinectPV2.JointType_SpineShoulder, KinectPV2.JointType_ShoulderRight);
  drawBone(joints, KinectPV2.JointType_SpineShoulder, KinectPV2.JointType_ShoulderLeft);
  drawBone(joints, KinectPV2.JointType_SpineBase, KinectPV2.JointType_HipRight);
  drawBone(joints, KinectPV2.JointType_SpineBase, KinectPV2.JointType_HipLeft);

  // Right Arm
  drawBone(joints, KinectPV2.JointType_ShoulderRight, KinectPV2.JointType_ElbowRight);
  drawBone(joints, KinectPV2.JointType_ElbowRight, KinectPV2.JointType_WristRight);
  drawBone(joints, KinectPV2.JointType_WristRight, KinectPV2.JointType_HandRight);
  drawBone(joints, KinectPV2.JointType_HandRight, KinectPV2.JointType_HandTipRight);
  drawBone(joints, KinectPV2.JointType_WristRight, KinectPV2.JointType_ThumbRight);

  // Left Arm
  drawBone(joints, KinectPV2.JointType_ShoulderLeft, KinectPV2.JointType_ElbowLeft);
  drawBone(joints, KinectPV2.JointType_ElbowLeft, KinectPV2.JointType_WristLeft);
  drawBone(joints, KinectPV2.JointType_WristLeft, KinectPV2.JointType_HandLeft);
  drawBone(joints, KinectPV2.JointType_HandLeft, KinectPV2.JointType_HandTipLeft);
  drawBone(joints, KinectPV2.JointType_WristLeft, KinectPV2.JointType_ThumbLeft);

  // Right Leg
  drawBone(joints, KinectPV2.JointType_HipRight, KinectPV2.JointType_KneeRight);
  drawBone(joints, KinectPV2.JointType_KneeRight, KinectPV2.JointType_AnkleRight);
  drawBone(joints, KinectPV2.JointType_AnkleRight, KinectPV2.JointType_FootRight);

  // Left Leg
  drawBone(joints, KinectPV2.JointType_HipLeft, KinectPV2.JointType_KneeLeft);
  drawBone(joints, KinectPV2.JointType_KneeLeft, KinectPV2.JointType_AnkleLeft);
  drawBone(joints, KinectPV2.JointType_AnkleLeft, KinectPV2.JointType_FootLeft);

  drawJoint(joints, KinectPV2.JointType_HandTipLeft);
  drawJoint(joints, KinectPV2.JointType_HandTipRight);
  drawJoint(joints, KinectPV2.JointType_FootLeft);
  drawJoint(joints, KinectPV2.JointType_FootRight);

  drawJoint(joints, KinectPV2.JointType_ThumbLeft);
  drawJoint(joints, KinectPV2.JointType_ThumbRight);

  drawJoint(joints, KinectPV2.JointType_Head);
}

//draw joint
void drawJoint(KJoint[] joints, int jointType) {
  pushMatrix();
  translate(joints[jointType].getX(), joints[jointType].getY(), joints[jointType].getZ());
  ellipse(0, 0, 25, 25);
  popMatrix();
}

//draw bone
void drawBone(KJoint[] joints, int jointType1, int jointType2) {
  pushMatrix();
  translate(joints[jointType1].getX(), joints[jointType1].getY(), joints[jointType1].getZ());
  ellipse(0, 0, 25, 25);
  popMatrix();
  line(joints[jointType1].getX(), joints[jointType1].getY(), joints[jointType1].getZ(), joints[jointType2].getX(), joints[jointType2].getY(), joints[jointType2].getZ());
}

//draw hand state
void drawHandState(KJoint joint) {
  noStroke();
  handState(joint.getState());
  pushMatrix();
  translate(joint.getX(), joint.getY(), joint.getZ());
  ellipse(0, 0, 70, 70);
  popMatrix();
}

/*
Different hand state
 KinectPV2.HandState_Open
 KinectPV2.HandState_Closed
 KinectPV2.HandState_Lasso
 KinectPV2.HandState_NotTracked
 */
void handState(int handState) {
  switch(handState) {
  case KinectPV2.HandState_Open:
    fill(0, 255, 0);
    break;
  case KinectPV2.HandState_Closed:
    fill(255, 0, 0);
    break;
  case KinectPV2.HandState_Lasso:
    fill(0, 0, 255);
    break;
  case KinectPV2.HandState_NotTracked:
    fill(255, 255, 255);
    break;
  }
}
