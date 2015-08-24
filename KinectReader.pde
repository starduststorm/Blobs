import java.io.RandomAccessFile;

public class KinectReader extends Thread
{
  RandomAccessFile pipe;
  HashMap<String, TrackingTarget> targets;
  int lastRead = 0;
  
  public KinectReader()
  {
    targets = new HashMap<String,TrackingTarget>();
    try {
      pipe = new RandomAccessFile("\\\\.\\pipe\\testpipe", "r");
    } catch (Exception e) {
      println("Error initializing pipe");
      e.printStackTrace();
    }
  }
  
  void finalize()
  {
    this.close();
  }
  
  public void run()
  {
    
    if (pipe == null) {
      println("No pipe!");
      return;
    }
    while (true) {
      try { 
        HashMap<String, TrackingTarget> uniquedTargets = new HashMap<String,TrackingTarget>();
        String records = pipe.readLine();
        if (lastRead != 0) {
          int time = millis() - lastRead;
          if(time > 70) {
            println("Last read was " + time + "ms ago");
          }
       }
        lastRead = millis();
        if (records != null && records.length() > 0) {
          for (String record : records.split(";")) {
            TrackingTarget tt = new TrackingTarget(record);
            uniquedTargets.put(tt.id, tt);
          }
        }
        synchronized(this) {
          targets = uniquedTargets;
        }
      } catch (Exception e) {
        e.printStackTrace();
        //println("Ceci n'est pas une pipe.");
      }
    }
  }
  
  public void close()
  {
    try {
      pipe.close();
    } catch (IOException e) {
      println("Error closing pipe");
      e.printStackTrace();
    }
  }
  
  HashMap<String, TrackingTarget> trackedTargets()
  {
    synchronized(this) {
      return targets;
    } //<>//
  }
}