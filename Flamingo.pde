
public enum FlamingoMode {
  WhereAmI,
  Parade,
  Mess,
  Test,
};

final int DirectionLeft = -1;
final int DirectionRight = 1;

final int kDyingAnimationDuration = 1 * 600;

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
  
  int life;
  int dyingStart;
  color impactTint;
  
  public Flamingo(int d)
  {
    speed = 1;
    direction = d;
    facingFront = true;
    swapHeadChance = 0.1;
    life = 2;
    
    legPose = rand.nextInt(legImages.length);
  }
  
  public boolean isDead()
  {
    return life == 0 && (millis() - dyingStart) > kDyingAnimationDuration;
  }
  
  public void tick()
  {
    if (life > 0) {
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
  }
  
  float deathAnimationFunction(float progress)
  {
    return 22.5 * progress * progress - 14.5 * progress;
  }
  
  public void draw()
  {
    colorMode(RGB, 255);
    blendMode(BLEND);
    PImage bodyImg = bodyImages[facingFront ? 0 : 1];
    PImage legsImg = legImages[this.legPose];
    
    pushMatrix();
    
    int impactAlpha = 255;
    if (dyingStart > 0) {
      float impactProgress = (millis() - dyingStart) / (float)kDyingAnimationDuration;
      impactAlpha = (int)(255 * (1 - impactProgress));
      translate(0, deathAnimationFunction(impactProgress));
    }
    
    if (impactTint != 0) {
      tint(impactTint, impactAlpha);
    } else {
      noTint();
    }
    
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
    if (life > 0 && !b.isDead()) {
      PVector pos = b.position;
      if (pos.y > 0 && pos.y < displayHeight) {
        float flamingoCenter = this.x + flamingoWidth / 2.0;
        return pos.x > flamingoCenter - 2 && pos.x < flamingoCenter + 2;
      }
    }
    return false;
  }
  
  public void impactWithBlobby(Blobby b)
  {
    println("Flamingo " + this + " hit by blobby " + b);
    assert life > 0;
    life -= 1;
    impactTint = b.blobbyColor;
    if (life == 0) {
      dyingStart = millis();
    }
    b.impact();
  }
}

// -------------------------------------------------------------------------------------------- //

public class FlamingoPattern extends IdlePattern
{
  private LinkedList<Flamingo> flamingos;
  
  FlamingoMode mode;
  int modeStart;
  int submode;
  int submodeStart;
  int lastAction;
  
  int spawnDuration; // seconds
  float messPeak; // peak chance to spawn during Mess
  boolean directionIsRandom;
  
  float spawnChance; // [0, 1] chance of adding a flamingo on tick
  float spawnRate; // flamingos per second (fps)
  int lastSpawnFromSpawnRate;
  
  int lastTick;
  int direction;
  
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
    spawnRate = 0.0;
    spawnDuration = 0;
    directionIsRandom = false;
    
    switch(mode) {
      case Test:
        spawnRate = 2.5;
        directionIsRandom = true;
        break;
      case WhereAmI:
        Flamingo f = spawnFlamingo(direction);
        f.swapHeadChance = 0;
        break;
      case Parade:
        spawnRate = 5;
        spawnDuration = 4;
        break;
      case Mess:
        spawnDuration = 25;
        messPeak = 0.1;
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
     
    FlamingoMode m;
    do {
      m = randomEnum(FlamingoMode.class);
    } while (m == FlamingoMode.Test);
    
    //m = FlamingoMode.Test;
    
    startMode(m);
    
    super.startPattern();
  }
  
  private void updateMode(int tickMillis)
  {
    if (directionIsRandom) {
      direction = randomDirection();
    }
    
    boolean keepSpawning = true;
    int spawnElapsed = millis() - modeStart;
    if (spawnDuration > 0) {
      if (spawnElapsed > spawnDuration * 1000) {
        spawnChance = 0;
        spawnRate = 0;
        keepSpawning = false;
      }
    }
    
    switch(mode) {
      case Test:
        break;
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
      case Mess:
        if (keepSpawning) {
          spawnChance = 0.5 * (1 + sin(spawnElapsed / (float)spawnDuration * 3.14159));
          spawnChance *= messPeak; // max density chance one flamingo ever 4 pixels
        }
        break;
      default:
        break;
    }
  }
  
  public void update()
  {
    final float frametime = 1000/30.0;
    
    int tickMillis = millis() - lastTick;
    if (tickMillis > frametime) {
      lastTick = millis();
      
      boolean spawnAllowed = (mode == FlamingoMode.Test || !this.isStopping());
      if (spawnAllowed && rand.nextFloat() < this.spawnChance) {
        spawnFlamingo(direction);
      }
      if (spawnAllowed && millis() - lastSpawnFromSpawnRate > 1/spawnRate * 1000) {
        spawnFlamingo(direction);
        lastSpawnFromSpawnRate = millis();
      }
      
      Iterator<Flamingo> it = flamingos.iterator();
      while (it.hasNext()) {
        Flamingo flamingo = it.next();
        flamingo.tick();
        if (flamingo.x + flamingoWidth > displayWidth + 20 || flamingo.x < -20) {
          it.remove();
        }
        if (flamingo.isDead()) {
          it.remove();
        }
      }
      
      updateMode(tickMillis);
    }
    
    for (Flamingo flamingo : flamingos) {
      flamingo.draw();
    }
    
    if (flamingos.size() == 0 && mode != FlamingoMode.Test) {
      if (this.isStopping()) {
        this.stopCompleted();
      } else {
        if (mode == FlamingoMode.WhereAmI && isRunning() && rand.nextFloat() < 0.3) {
          // 40% chance of getting chased by a parade
          startMode(FlamingoMode.Parade);
          // but denser
          spawnDuration = 15;
          messPeak = 0.18;
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