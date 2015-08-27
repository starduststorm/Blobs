public class BlobManager
{
  KinectReader reader;
  HashMap<String, Blob> blobs;
  HashMap<String,Blob> awolBlobs;
  
  public BlobManager()
  {
    reader = new KinectReader();
    reader.start();
    blobs = new HashMap<String, Blob>();
    awolBlobs = new HashMap<String,Blob>();
    
  }
  
  public boolean hasBlobs()
  {
    return blobs.size() > 0 || awolBlobs.size() > 0;
  }
  
  public void update()
  { 
    HashMap<String,TrackingTarget> targets = reader.trackedTargets();
    
    if (targets != null && targets.size() > 0) {
      for (TrackingTarget tt : targets.values()) {
        float targetPosition = tt.position * width;
        
        Blob blob = blobs.get(tt.id);
        if (blob == null) {
          blob = awolBlobs.get(tt.id);
          if (blob != null) {
            println("Found blob " + tt.id + " with original id");
            blobs.put(tt.id, blob);
            awolBlobs.remove(tt.id);
            blob.awol = false;
          }
        }
        if (blob == null) {
          // The Kinect is not tracking this blob. But it may have disappeared for only a short time.
          // Check for a blob in a very similar position in the recently-disappeared list.
          Iterator it = awolBlobs.entrySet().iterator();
          while (it.hasNext()) {
            Map.Entry pair = (Map.Entry)it.next();
            Blob awolBlob = (Blob)pair.getValue();
            String awolID = (String)pair.getKey();
            if (abs(awolBlob.x - targetPosition) < 10) {
              println("Found blob " + awolID + ", assigning new ID " + tt.id);
              blob = awolBlob;
              blob.awol = false;
              it.remove();
              blobs.remove(awolID);
              blobs.put(tt.id, blob);
            }
          }
          if (blob == null) {
            println("New blob " + tt.id + " at " + tt.position);
            blob = new Blob();
            blobs.put(tt.id, blob);
          }
        }
        if (!tt.stale) {
          blob.lastSeen = millis();
          blob.awol = false;
          blob.setX(targetPosition);
          
          blob.setLeftHandOut(tt.leftHandOut);
          blob.setRightHandOut(tt.rightHandOut);
        }
      }
    }
    
    // Mark any Blobs that are no longer tracked as awol
    // FIXME: Use iterator
    {
      Iterator it = blobs.entrySet().iterator();
      while (it.hasNext()) {
       Map.Entry pair = (Map.Entry)it.next();
       String id = (String)pair.getKey();
       Blob blob = (Blob)pair.getValue();
       if ((targets == null || !targets.containsKey(id)) && !blob.awol) {
         println("Blob " + id + " is awol");
         blob.awol = true;
         it.remove();
         awolBlobs.put(id, blob);
       }
      }
    }
    
    // Remove blobs that have been awol too long
    Iterator it = awolBlobs.entrySet().iterator();
    while (it.hasNext()) {
      Map.Entry pair = (Map.Entry)it.next();
      Blob awolBlob = (Blob)pair.getValue();
      String awolID = (String)pair.getKey();
      //println("awol blob " + awolID + " last seen " + (millis() - awolBlob.lastSeen) + " millis ago");
      if (millis() - awolBlob.lastSeen > 3000) {
        println("Expiring awol blob " + awolID);
        it.remove();
      }
    }
    
    // For any blobs that were not updated this frame, keep them going at present velocity
    for (String id : blobs.keySet()) {
      boolean stale = false;
      if (targets == null || !targets.containsKey(id)) {
        stale = true;
      } else {
        TrackingTarget tt = targets.get(id);
        stale = tt.stale;
        tt.stale = true;
      }
      if (stale) {
        Blob blob = blobs.get(id);
        blob.coast();
      }
    }
    
    // Draw the tracked blobs!
    for (Blob blob : blobs.values()) {
      //println("Drawing blob " + blob + " at " + blob.x);
      //if (!blob.awol) {
        blob.draw();
      //}
    }
  }
  
  public void close()
  {
    reader.close();
  }
}