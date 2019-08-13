
public class TextBanner extends IdlePattern
{
  PFont font;
  final int fontSize = 11;
  
  float textHue = 0;
  int textMode = -1;
  float textX = 30;
  float textDirection = 0.4;
  int timeTextStarted = -1;
  
  public TextBanner(int displayWidth, int displayHeight)
  {
    super(displayWidth, displayHeight);
    
    font = createFont("Leelawadee", fontSize, false);
    // Latha, Consolas
    textFont(font, fontSize);
  }
  
  public void startPattern()
  {
    textMode = (int)random(0, 3);
    super.startPattern();
  }
  
  public void update()
  {
    draw();
  }
  
  public void draw()
  {
    blendMode(BLEND);
    noFill();
    
    colorMode(HSB, 100);

    drawText();
  }
  
  void drawText()
  {
    //textSize(8);
    
    blendMode(BLEND);
    int timeSinceText = millis() - timeTextStarted;
    float fadeInAlpha = 100 * (timeSinceText < 3000 ? timeSinceText / 3000.0 : 1.0);
    
    if (textMode == 0) {
      colorMode(HSB, 100);
      fill(textHue, 100, fadeInAlpha);
      text("M O A R", width / 2 - 20 + 90 * sin(millis() / 1000.0), height);
      
    } else if (textMode == 1) {
      colorMode(HSB, 100);
      fill(textHue, 100, fadeInAlpha);
      pushMatrix();
      translate(width / 2, height / 2);
      scale(0.8 + 2 * (1 + sin(millis() / 1000.0)));
      text("M O A R", -20, height / 2);
      popMatrix();
      
    } else if (textMode == 2) {
      colorMode(HSB, 100);
      fill(textHue, 100, fadeInAlpha);
      pushMatrix();
      translate(textX, height / 2);
      rotate(millis() / 500.0);
      text("M O A R", -16, height / 2);
      popMatrix();
      textX += textDirection;
      if ((textDirection > 0 && textX > 210) || (textDirection < 0 && textX < 30)) {
        textDirection *= -1;
      }
    }
    //else if (textMode == 3) {
    //  int counter = (int)(millis() / 10.0);
      
    //  colorMode(HSB, 100);
    //  for (int y = 0; y < height; ++y) {
    //    for (int x = 0; x < width; ++x) {
    //      stroke((11 * x + counter) % 100, 100, 50 * (1 + sin(x / 10.0 + millis() / 500.0)));
    //      point(x, y);
    //    }
    //  }
      
    //  colorMode(RGB, 100);
    //  fill(100, 0, 0, fadeInAlpha);
    //  text("M O A R", width / 2 - 20, height);
    //}
    
    textHue += 0.2;
    if (textHue >= 100) {
      textHue = 0;
    }
    
    if (isStopping()) {
      stopCompleted();
    }
  }
}