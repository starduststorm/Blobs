
public class RainbowPattern extends IdlePattern
{
  
  public RainbowPattern(int displayWidth, int displayHeight)
  {
    super(displayWidth, displayHeight);
  }
  
  public void startPattern()
  {
    super.startPattern();
  }
  
  public void update()
  {
    draw();
  }
  private float startY = 0;
  private float startX = 0;
  
  public void draw()
  {
    blendMode(BLEND);
    noFill();
    
    colorMode(HSB, 100);
    //for (int i = 0; i < displayHeight; ++i) {
    //  stroke((startY + i * 100 / displayHeight + 100) % 100, 100, 20);
    //  //int y = ((int)startY + i) % displayHeight + 1;
    //  line(0, i + 1, displayWidth, i + 1);
    //}
    //startY += sin(millis() / 1000.0);
    
    
    int segs = 50;
    for (int i = 0; i < segs; ++i) {
      stroke((i * 100 / segs) % 100, 100, 25);
      line(startX + i, 0, startX + i, displayHeight);
    }
    startX = (displayWidth - segs) / 2.0 + sin(millis() / 1000.0) * (displayWidth - segs) / 2.0;
  }
}
