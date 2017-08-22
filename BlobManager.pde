
Blob blob = null;

float kBlobCoastThreshold = 50;
float kBlobDisappearThreshold = 200;
float kBlobExpireThreshold = 3000;
final float kBlobTrackTolerance = 10.0;

public class BlobManager
{
  KinectPV2 kinect;
  HashSet<Blob> blobs;
  
  FlamingoPattern flamingoPattern;
  
  public BlobManager(KinectPV2 kinect)
  {
    this.kinect = kinect;
    blobs = new HashSet<Blob>();
  }
  
  public boolean hasBlobs()
  {
    return blobs.size() > 0;
  }
  
  public boolean anyVisualDebug()
  {
    for (Blob blob : blobs) {
      if (blob.visualDebug) {
        return true;
      }
    }
    return false;
  }
    
  private void _updateBlobs()
  {
    ArrayList<KSkeleton> skeletons = kinect.getSkeletonDepthMap();
    
    // We have no concept of "id" for KSkeleton, so we have to rely on rough position to track the same object
    // from frame to frame. eww.
        
    HashSet<Blob> searchList = new HashSet<Blob>(blobs);
    
    int millis = millis();
    
    for (KSkeleton skeleton : skeletons) {
      if (skeleton.isTracked()) {
        KJoint[] joints = skeleton.getJoints();
        KJoint head = joints[KinectPV2.JointType_Head];
        PVector p = coordsForJoint(head);
        if (!Float.isFinite(p.x) || !Float.isFinite(p.y)) {
          // Tends to happen as bodies move out of the frame?
          continue;
        }
                
        Blob blob = null;
        // First search for this skeleton in the currently-tracked list
        for (Iterator<Blob> it = searchList.iterator(); it.hasNext();) {
          Blob considerBlob = it.next();
          if (abs(p.x - (considerBlob.x + considerBlob.smoothedVelocity())) < kBlobTrackTolerance) {
            blob = considerBlob;
            it.remove(); // remove this from the search list so we don't find it twice
            break;
          }
        }
        if (blob == null) {
          println("Making new blob at " + p.x);
          blob = new Blob();
          blobs.add(blob);
        }
        blob.setX(p.x);
        if (millis - blob.lastSeen > kBlobDisappearThreshold) {
          // This blob had disappeared, so we should set the blob age to 0 so it fades back in.
          blob.birthdate = millis;
        }
        blob.lastSeen = millis;
        blob.updateWithSkeleton(skeleton);
      }
    }
    
    for (Iterator<Blob> it = blobs.iterator(); it.hasNext(); ) {
      Blob blob = it.next();
      int timeSince = millis - blob.lastSeen;
      
      // Coast blobs that weren't updated this frame
      if (timeSince > 0 && timeSince < kBlobDisappearThreshold) {
        blob.coast();
      }
      
      blob.checkCollisionWithFlamingos(flamingoPattern.flamingos);
      
      // Remove blobs that are very awol
      if (timeSince > kBlobExpireThreshold) {
        println("Expiring awol blob " + blob);
        it.remove();
      }
      
      // Draw blobs that aren't too awol
      if (timeSince < kBlobDisappearThreshold) {
        //println("Drawing blob " + blob + " at " + blob.x);
        blob.draw();
      }
    }
    
    // Only allow super blobbies when there's only one person
    if (skeletons.size() > 1) {
      for (Blob blob : blobs) {
        blob.superBlobbies = false;
      }
    }
  }
  
  public void update()
  {
    _updateBlobs();    
    
    // Draw FPS if in visual debug mode anywhere
    if (this.anyVisualDebug()) {
      blendMode(BLEND);
      noStroke();
      fill(#000000);
      rect(0, 0, 22, height);
      fill(#FFFFFF);
      text(String.format("%.1f", frameRate), 2, displayHeight - 1);
    }
  }
  
  public void close()
  {
    //reader.close();
  }
}