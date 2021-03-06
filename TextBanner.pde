
final String campName = "C A M P  M O A R";

public class TextBanner extends IdlePattern
{
  PFont font;
  final int fontSize = 11;
  
  color textColor;
  int textMode = -1;
  float textX = 30;
  float textDirection = 0.4;
  int timeTextStarted = -1;
  int submode;
  long modeMillis;
  long submodeMillis;
  
  float followLeader;
  Palette palette;
  int paletteValue;
  int paletteDirection = 1;
  
  public TextBanner(int displayWidth, int displayHeight)
  {
    super(displayWidth, displayHeight);
    
    font = createFont("Leelawadee", fontSize, false);
    // Latha, Consolas
    textFont(font, fontSize);
  }
  
  public void startPattern()
  {
    palette = palettes.randomNonBlackPalette();
    paletteValue = rand.nextInt(0xFF);
    textMode = (int)random(0, 4);
    submode = 0;
    modeMillis = millis();
    submodeMillis = modeMillis;
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
  
  void tickTextColor() {
    if (paletteValue >= 255) {
      paletteDirection = -1;
    } else if (paletteValue <= 0) {
      paletteDirection = 1;
    }
    paletteValue += paletteDirection;
    textColor = palette.getColor(paletteValue);
  }
  
  void drawText()
  {
    clip(0, 0, displayWidth, displayHeight);
    blendMode(BLEND);
    int timeSinceText = millis() - timeTextStarted;
    float fadeInAlpha = min(100, 100 * (timeSinceText < 3000 ? timeSinceText / 3000.0 : 1.0));
    
    if (isStopping()) {
      fadeInAlpha = max(0, 100 * (1 - (millis() - stopMillis) / 1000.));
    }
    if (textMode == 0) {
      tickTextColor();
      colorMode(HSB, 100);
      fill(textColor, fadeInAlpha);
      text("M O A R", displayWidth / 2 - 20 + 90 * sin(millis() / 1000.0), displayHeight);
    } else if (textMode == 1) {
      tickTextColor();
      colorMode(HSB, 100);
      fill(textColor, fadeInAlpha);
      pushMatrix();
      translate(displayWidth / 2, displayHeight / 2);
      scale(0.8 + 2 * (1 + sin(millis() / 1000.0)));
      text("M O A R", -20, displayHeight / 2);
      popMatrix();
      
    } else if (textMode == 2) {
      tickTextColor();
      colorMode(HSB, 100);
      fill(textColor, fadeInAlpha);
      pushMatrix();
      translate(textX, displayHeight / 2);
      rotate(millis() / 500.0);
      text("M O A R", -15, displayHeight / 2);
      popMatrix();
      textX += textDirection;
      if ((textDirection > 0 && textX > 210) || (textDirection < 0 && textX < 30)) {
        textDirection *= -1;
      }
    } else if (textMode == 3) {
      lineyMode(fadeInAlpha);
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
    
    noClip();
    
    if (isRunning() && runTime() > 45 * 1000) {
      lazyStop();
    }
    if (isStopping() && fadeInAlpha <= 0) {
      stopCompleted();
    }
  }
  
  int nextSubmode() {
    submodeMillis = millis();
    return ++submode;
  }

  void lineyMode(float fadeInAlpha) {
    long submodeDuration = millis() - submodeMillis;
      
      final int textSize = 88;
      blendMode(BLEND);
      
      int textStart = displayWidth / 2 - textSize/2;
      
      switch (submode) {
        case 0: {
          int typedLength = (int)(submodeDuration / 1000. * 8);
          textColor = palette.getColor(paletteValue);
          fill(textColor);
          text(campName.substring(0, min(typedLength, campName.length())), textStart, displayHeight);
          if (typedLength > campName.length() + 2) {
            nextSubmode();
          }
          break;
        }
        case 1: {
          fill(textColor, fadeInAlpha);
          text(campName, textStart, displayHeight);
          int textEnd = displayWidth / 2 + textSize / 2;
          for (int i = 1; i < 20; ++i) {
            //stroke(Math.floorMod((i - (int)followLeader/4) * 37, 100), 100, 100);   // walk through hue
            stroke(palette.getColor((i - (int)followLeader/4) * 7), fadeInAlpha);
            float lineHeight = max((sin(followLeader/100.) + 1) * displayHeight/2, (sin(i + followLeader/8.) + 1) * displayHeight/2);
            float x1 = textStart - i * 4 - (int)followLeader % 4 - 0.5;
            float x2 = textEnd + i * 4 + (int)followLeader % 4 + 0.5;
            line(x1, displayHeight / 2 - lineHeight / 2, x1, displayHeight / 2 + lineHeight / 2);
            line(x2, displayHeight / 2 - lineHeight / 2, x2, displayHeight / 2 + lineHeight / 2);
          }
          followLeader+= 0.5;
          if (followLeader % 100 == 0) {
            textColor = palette.getColor(rand.nextInt(0xFF));
          }
        }
      }
  }
}

// FIXME: This is broken (the second text draws over the first text instead of blending with it) and it's something to do wit the "copy" function used in the main file.

/*
void splodyMode(float fadeInAlpha) {
    //background(0, 0,0);
    pushMatrix();
    String campName = "C A M P  M O A R";
    
    long submodeDuration = millis() - submodeMillis;
    
    final int textSize = 88;
    blendMode(BLEND);
    
    switch (submode) {
      case 0: {
        int typedLength = (int)(submodeDuration / 1000. * 8);
        
        fill(textHue, 100, fadeInAlpha);
        text(campName.substring(0, min(typedLength, campName.length())), displayWidth / 2 - textSize/2, displayHeight);
        if (typedLength > campName.length() + 2) {
          nextSubmode();
        }
        break;
      }
      case 1: {
        
        // FIXME: even if this worked it's kinda boring and the lo-fi text doesn't look good. the fadedown won't be good on leds. the low-contrast makes it messy.
        // Just do a series of colorful vertical lines extending outward! use a solid color for text.
        
        noFill();
        stroke(100);
        rect(displayWidth / 2 - textSize/2, 0, textSize, displayHeight);

        noStroke();
        fill(textHue, 100, fadeInAlpha);
        text(campName, displayWidth / 2 - textSize/2, displayHeight);
        
        float scale = 1 + submodeDuration / 2000.;
        long alpha = (long)max(0, 100 * (1 - submodeDuration / 2000.));
        //translate(textSize/2., displayHeight/2.);
        //scale(scale, scale);
        //translate(-textSize/2. * scale, -displayHeight/2. * scale);
        fill(textHue, 100, 100, alpha);
        float z = submodeDuration / 100.;
        text(campName, displayWidth / 2 - textSize/2 , displayHeight + z/3, z);
        if (submodeDuration > 2000) {
          //nextSubmode();
        }
        break;
      } 
      case 2: {
        lazyStop();
        break;
      }
    }
    popMatrix();
  }
  */
