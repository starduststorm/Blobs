public abstract class IdlePattern
{
  public int displayWidth;
  public int displayHeight;
  
  protected int startMillis = -1;
  protected int stopMillis = -1;
  protected int startInteractionMillis = -1;
  
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
  
  public boolean wantsInteraction()
  {
    return false;
  }
  
  public final void startInteraction()
  {
    if (this.isRunning() && !this.isInteracting()) {
      println("Starting interaction with " + this + "...");
      assert wantsInteraction();
      this.startInteractionMillis = millis();
      interactionStarted();
    }
  }
  
  public final void stopInteraction()
  {
    if (this.startInteractionMillis != -1) {
      println("Stopping interaction with " + this + "...");
      this.startInteractionMillis = -1;
      this.interactionStopped();
    }
  }
  
  public final boolean isInteracting()
  {
    return this.startInteractionMillis != -1;
  }
  
  public void interactionStarted()
  {
    // override point
  }
  
  public void interactionStopped()
  {
    // override point
  }
  
  public void lazyStop()
  {
    if (this.isRunning()) {
      println("Stopping " + this + "...");
      this.stopMillis = millis();
    } else {
      println("Can't lazy stop, not running " + this + "!");
    }
  }
  
  public final void stopCompleted()
  {
    println("Stopped " + this + ".");
    this.stopInteraction();
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