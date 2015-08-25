
public class TrackingTarget
{
  public boolean stale;
  public String id;
  public float position;
  public float distance;
  public boolean leftHandOut;
  public boolean rightHandOut;
  
  //public TrackingTarget(String id, float position, float distance)
  //{
  //  this.stale = false;
  //  this.id = id;
  //  this.position = position;
  //  this.distance = distance;
  //}
  
  public TrackingTarget(String record)
  {
     this.stale = false;
     String[] split = record.split(" ");
     this.id = split[0];
     this.position = Float.parseFloat(split[1]);
     this.distance = Float.parseFloat(split[2]);
     this.leftHandOut = Boolean.parseBoolean(split[3]);
     this.rightHandOut = Boolean.parseBoolean(split[4]);
  }
}