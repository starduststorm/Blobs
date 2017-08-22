
public enum FlamingoMode {
  WhereAmI,
  Parade,
};

final int DirectionLeft = -1;
final int DirectionRight = 1;

final int kImpactDuration = 1 * 1000;

public static <T extends Enum<?>> T randomEnum(Class<T> C)
{
  Random random = new Random();
  int x = random.nextInt(C.getEnumConstants().length);
  return C.getEnumConstants()[x];
}

String[][] body = { {"000000102",
                     "000003130",
                     "003113130",
                     "031111130",
                     "311111130"},
                  
                    {"000020100",
                     "000003130",
                     "003113130",
                     "031111130",
                     "311111130"}
                };

color[] bodyColors = {color(0,0,255,0), color(255,20,147), color(220, 106, 5), color(0,0,0,220)};

PImage bodyImages[] = null;

String[][] legs = { {"001100",
                     "010010",
                     "100001"},
                   
                    {"001100",
                     "110100",
                     "000010"},

                    {"001100",
                     "011100",
                     "000100"},

                    {"001100",
                     "001110",
                     "001000"},

                    {"001100",
                     "001011",
                     "010000"}
};

color[] legColors = {color(0,0,0,0), color(100, 50, 80)};

PImage legImages[] = null;

int bodyWidth = body[0][0].length();
int bodyHeight = body[0].length;

int legsWidth = legs[0][0].length();
int legsHeight = legs[0].length;

int flamingoWidth = max(bodyWidth, legsWidth);
int flamingoHeight = max(bodyHeight, legsHeight);

private PImage[] imagesForData(String[][] data, color[] colors)
{
  colorMode(RGB, 255);
  PImage images[] = new PImage[data.length];
  
  int imgWidth = data[0][0].length();
  int imgHeight = data[0].length;
  
  for (int poseIndex = 0; poseIndex < data.length; ++poseIndex) {
    String[] pose = data[poseIndex];
    PImage img = createImage(imgWidth, imgHeight, ARGB);
    img.loadPixels();
    for (int lineNum = 0; lineNum < imgHeight; lineNum++) {
      String line = pose[lineNum];
      for (int chr = 0; chr < line.length(); ++chr) {
        char c = line.charAt(chr);
        int colorIndex = Character.getNumericValue(c);
        img.pixels[lineNum * imgWidth + chr] = colors[colorIndex];
      }
      println();
    }
    img.updatePixels();
    images[poseIndex] = img;
  }
  return images;
}

// ------------------------------------------------------- //

public class Flamingo {
  int x;
  boolean facingFront;
  int legPose;
  int direction; // 1 or -1
  int speed; // pixels / tick at the moment
  float swapHeadChance;
  
  int impactTime;
  color impactTint;
  
  public Flamingo(int d)
  {
    speed = 1;
    direction = d;
    facingFront = true;
    swapHeadChance = 0.1;
    
    legPose = rand.nextInt(legImages.length);
  }
  
  public void tick()
  {
    // preen
    if (rand.nextFloat() < swapHeadChance) {
      facingFront = rand.nextBoolean();
    }
    
    // may pause
    if (rand.nextInt(100) > 0) {
      assert direction != 0;
      x += direction * speed;
      if (speed != 0) {
        legPose = (legPose + 1) % legImages.length;
      } else {
        legPose = 0;
      }
    }
  }
  
  public void draw()
  {
    blendMode(BLEND);
    PImage bodyImg = bodyImages[facingFront ? 0 : 1];
    PImage legsImg = legImages[this.legPose];
    
    if (impactTime > 0) {
      color c = impactTint;
      byte alpha = (byte)(255 * (1 - (millis() - impactTime) / (float)kImpactDuration));
      c = (c & 0xffffff) | (alpha << 24); 
      tint(impactTint);
    }
    
    pushMatrix();
    translate(x, 0, 0);
    scale(direction, 1, 1);
    if (direction == DirectionLeft) {
      translate(-flamingoWidth, 0, 0);
    }
    
    image(bodyImg, 0, 0);
    image(legsImg, 1, bodyImg.height);
    popMatrix();
  }
  
  public boolean collidesWithBlobby(Blobby b)
  {
    if (hasBeenImpacted() || b.isDead()) {
      return false;
    }
    float px = b.position.x;
    float flamingoCenter = this.x + flamingoWidth / 2.0;
    return px > flamingoCenter - 1 && px < flamingoCenter + 1;
  }
  
  public void impactWithBlobby(Blobby b)
  {
    impactTime = millis();
    impactTint = b.blobbyColor;
    b.impact();
  }
  
  public boolean hasBeenImpacted()
  {
    return impactTime > 0;
  }
}

// ------------------------------------------------------- //

public class FlamingoPattern extends IdlePattern
{
  private LinkedList<Flamingo> flamingos;
  
  FlamingoMode mode;
  int modeStart;
  int submode;
  int submodeStart;
  int lastAction;
  
  int paradeDuration; // seconds
  float paradePeak; // peak chance to spawn
  boolean directionIsRandom;
  
  float spawnChance; // [0, 1] chance of adding a flamingo on tick
  
  int lastTick;
  int direction;
  final int justhowdamnbigtheparadeis = 20;
  
  public String toString()
  {
    return "FlamingoPattern mode " + mode;
  }
  
  public FlamingoPattern(int displayWidth, int displayHeight)
  {
    super(displayWidth, displayHeight);
    
    if (bodyImages == null) {
      bodyImages = imagesForData(body, bodyColors);
    }
    if (legImages == null) {
      legImages = imagesForData(legs, legColors);
    }
    
    flamingos = new LinkedList<Flamingo>();
  }
  
  void enterSubmode(int sm)
  {
    submode = sm;
    submodeStart = millis();
  }
  
  Flamingo spawnFlamingo(int direction)
  {
    Flamingo f = new Flamingo(direction);
    if (direction > 0) {
      f.x = -flamingoWidth;
    } else {
      f.x = displayWidth + flamingoWidth;
    }
    flamingos.addLast(f);
    return f;
  }
  
  void startMode(FlamingoMode m)
  {
    mode = m;
    modeStart = millis();
    enterSubmode(0);
    spawnChance = 0.0;
    directionIsRandom = false;
    
    switch(mode) {
      case WhereAmI:
        Flamingo f = spawnFlamingo(direction);
        f.swapHeadChance = 0;
        break;
      case Parade:
        paradeDuration = 25;
        paradePeak = 0.1;
        if (rand.nextFloat() < 0.3) {
          directionIsRandom = true;
        }
        break;
    }
  }
  
  int randomDirection()
  {
    return (rand.nextBoolean() ? DirectionRight : DirectionLeft);
  }
  
  // ----------------------- Public methods ---------------------- //
  
  public void startPattern()
  {
    direction = randomDirection();
    
    startMode(randomEnum(FlamingoMode.class));
    
    super.startPattern();
  }
  
  private void updateMode(int tickMillis)
  {
    switch(mode) {
      case WhereAmI: {
        if (flamingos.size() > 0) {
          Flamingo f = flamingos.getFirst();
          if (submode == 0) {
            if (f.x == displayWidth / 2 + 12) {
              f.speed = 0;
              lastAction = millis();
              enterSubmode(1);
            }
          } else if (submode == 1) {
            if (millis() - lastAction > 1000) {
              if (millis() - submodeStart > 4500) {
                enterSubmode(2);
              } else {
                f.direction *= -1;
              }
              lastAction = millis();
            }
          } else if (submode == 2) {
            direction = randomDirection();
            f.direction = direction;
            f.facingFront = true;
            f.speed = 1;
            enterSubmode(3);
          }
        }
        break;
      }
      case Parade:
        if (directionIsRandom) {
          direction = randomDirection();
        }
        int paradeElapsed = millis() - modeStart;
        if (paradeElapsed < paradeDuration * 1000) {
          spawnChance = 0.5 * (1 + sin(paradeElapsed / (float)paradeDuration * 3.14159));
          spawnChance *= paradePeak; // max density chance one flamingo ever 4 pixels
        } else {
          spawnChance = 0;
        }
        break;
    }
  }
  
  public void update()
  {
    final float frametime = 1000/30.0;
    
    int tickMillis = millis() - lastTick;
    if (tickMillis > frametime) {
      lastTick = millis();
      
      if (!this.isStopping() && rand.nextFloat() < this.spawnChance) {
        spawnFlamingo(direction);
      }
      
      Iterator<Flamingo> it = flamingos.iterator();
      while (it.hasNext()) {
        Flamingo flamingo = it.next();
        flamingo.tick();
        if (flamingo.x + flamingoWidth > displayWidth + 20 || flamingo.x < -20) {
          it.remove();
        }
        if (millis() - flamingo.impactTime > kFlamingoImpactDuration) {
          it.remove();
        }
      }
      
      updateMode(tickMillis);
    }
    
    for (Flamingo flamingo : flamingos) {
      flamingo.draw();
    }
    
    if (flamingos.size() == 0) {
      if (this.isStopping()) {
        this.stopCompleted();
      } else {
        if (mode == FlamingoMode.WhereAmI && isRunning() && rand.nextFloat() < 0.3) {
          // 40% chance of getting chased by a parade
          startMode(FlamingoMode.Parade);
          // but denser
          paradeDuration = 15;
          paradePeak = 0.18;
        } else if (isRunning() && millis() - modeStart > 5000) {
          // no flamingos and we've been running for more than 5 seconds as a sanity check 
          lazyStop();
        }
      }
    }
  }
  
  boolean wantsToIdleStop()
  {
    return false;
  }
}