public abstract class IdlePattern
{
  public int displayWidth;
  public int displayHeight;
  
  protected int startMillis = -1;
  protected int stopMillis = -1;
  
  public IdlePattern(int displayWidth, int displayHeight)
  {
    this.displayWidth = displayWidth;
    this.displayHeight = displayHeight;
  }
  
  public boolean wantsToRun()
  {
    return true;
  }
  
  public void startPattern()
  {
    println("Starting " + this + "...");
    this.startMillis = millis();
    this.stopMillis = -1;
  }
  
  public boolean wantsToIdleStop()
  {
    return true;
  }
  
  public void lazyStop()
  {
    println("Stopping " + this + "...");
    this.stopMillis = millis();
  }
  
  public final void stopCompleted()
  {
    println("Stopped " + this + ".");
    this.stopMillis = -1;
    this.startMillis = -1;
  }
  
  public boolean isRunning()
  {
    return startMillis != -1 && this.isStopping() == false;
  }
  
  public boolean isStopping()
  {
    return this.stopMillis != -1;
  }
  
  public abstract void update();
  
  public void idleUpdate()
  {
  }
}