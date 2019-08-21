
public enum FlamingoMode {
  WhereAmI,
  Parade,
  Mess,
  War,
  Test,
  Nyan,
  ConeDown,
  ConesOnly,
};

final int DirectionLeft = -1;
final int DirectionRight = 1;

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
                     "311111130"}, // regular
                  
                    {"000020100",
                     "000003130",
                     "003113130",
                     "031111130",
                     "311111130"}, // look back
                     
                    {"000000000",
                     "000000311",
                     "003113132",
                     "031111130",
                     "311111130"}, // sad
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

color legColors[] = {color(0,0,0,0), color(100, 50, 80)};

PImage legImages[] = null;

int bodyWidth = body[0][0].length();
int bodyHeight = body[0].length;

int legsWidth = legs[0][0].length();
int legsHeight = legs[0].length;

int flamingoWidth = max(bodyWidth, legsWidth);
int flamingoHeight = max(bodyHeight, legsHeight);

String[][] cone = { {"0000000",
                     "0222000",
                     "2222200",
                     "2222200",
                     "0111000",
                     "0111000",
                     "0010000",
                     "0000000"},
                         
                    {"0000000",
                     "0000000",
                     "0000000",
                     "0010000",
                     "0111000",
                     "0111000",
                     "0222200",
                     "2222222"},
};
int coneWidth = cone[0][0].length();

PImage coneImages[] = null;

color coneColor = #FF9800;
// FIXME: pallettes/sequences for ice cream colors. put GQ flag + other flags in there!
color[] iceCreamColors = {#E91E63, #795548, #ffffff, #fff8e1, #00bcd4, #00e676}; 

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

public abstract class Target {
  float x;
  int direction; // 1 or -1
  float speed; // pixels / tick at the moment
  
  int life;
  int dyingStart;
  color impactTint;
  
  int deathAnimationDuration = 1 * 600;
  
  public Target(int startDirection, int startLife)
  {
    speed = 1;
    direction = startDirection;
    life = startLife;
    dyingStart = 0;
  }
  
  public boolean isDead()
  {
    return life == 0 && dyingStart > 0 && (millis() - dyingStart) > deathAnimationDuration;
  }
  
  public void tick() { }
  public void draw() { }
  
  void applyDeathAnimation(float progress)
  {
    float dropoff = 22.5 * progress * progress - 14.5 * progress;
    translate(0, dropoff);
    
    int impactAlpha = (int)(255 * (1 - progress));
    
    if (impactTint != 0) {
      tint(impactTint, impactAlpha);
    } else {
      noTint();
    }
  }
  
  public void drawTarget()
  {
    colorMode(RGB, 255);
    blendMode(BLEND);
    
    pushMatrix();
    
    float deathAnimationProgress = (dyingStart > 0 ? (millis() - dyingStart) / (float)deathAnimationDuration : 0);
    applyDeathAnimation(deathAnimationProgress);
    
    translate((int)x, 0, 0);
    scale(direction, 1, 1);
    if (direction == DirectionLeft) {
      translate(-width(), 0, 0);
    }
    
    draw();
    
    popMatrix();
  }
  
  public boolean collidesWithBlobby(Blobby b)
  {
    if (life > 0 && !b.isDead()) {
      PVector pos = b.position;
      if (pos.y > 0 && pos.y < displayHeight) {
        float center = this.x + width() / 2.0;
        return pos.x > center - 2 && pos.x < center + 2;
      }
    }
    return false;
  }
  
  public void checkForDeath() {
    if (life == 0 && dyingStart == 0) {
      dyingStart = millis();
    }
  }
  
  public void impactWithBlobby(Blobby b)
  {
    println("Target " + this + " hit by blobby " + b);
    assert life > 0;
    life -= 1;
    impactTint = b.blobbyColor;
    checkForDeath();
    b.impact();
  }
  
  public abstract int width();
};

public class Flamingo extends Target {
  boolean facingFront;
  int legPose;
  float swapHeadChance;
  boolean sad;
  boolean usePauses = false;
  
  public Flamingo(int startDirection, int startLife)
  {
    super(startDirection, startLife);
    facingFront = true;
    swapHeadChance = 0.1;
    
    legPose = rand.nextInt(legImages.length);
  }
  
  public int width() {
    return flamingoWidth;
  }
  
  public void tick() {
    super.tick(); //<>//
    if (life > 0) {
      // preen
      if (rand.nextFloat() < swapHeadChance) {
        facingFront = rand.nextBoolean();
      }
      
      if (!usePauses || rand.nextInt(100) > 0) {
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
  
  public void draw() {
    PImage bodyImg = bodyImages[sad ? 2 : (facingFront ? 0 : 1)];
    PImage legsImg = legImages[this.legPose];
    image(bodyImg, 0, 0);
    image(legsImg, 1, bodyImg.height);
  }
}


public class Cone extends Target {
  PImage coneImages[];
  
  public Cone(int startDirection, int startLife) {
    super(startDirection, startLife);
    
    deathAnimationDuration = 1400;
    
    color colors[] = {#000000, coneColor, iceCreamColors[rand.nextInt(iceCreamColors.length)]};
    coneImages = imagesForData(cone, colors);
  }
  
  public int width() { //<>//
    return coneWidth;
  }
  
  public void tick() {
    super.tick();
    if (life > 0) {
      assert direction != 0;
      x += direction * speed;
    }
  }
  
  void applyDeathAnimation(float progress) {
    int impactAlpha = (int)(255 * (1 - progress));
    
    if (impactAlpha < 255) {
      tint(255, impactAlpha);
    } else {
      noTint();
    }
  }
  
  public void draw() {
    PImage coneImage = coneImages[life > 0 ? 0 : 1];
    image(coneImage, 0, 0);
  }
}

// -------------------------------------------------------------------------------------------- //

public class FlamingoPattern extends IdlePattern
{
  private LinkedList<Target> flamingos;
  
  FlamingoMode mode;
  int modeStart;
  int submode;
  int submodeStart;
  int lastAction;
  int deathToll;
  
  int spawnDuration; // seconds
  float messPeak; // peak chance to spawn during Mess
  boolean directionIsRandom;
  
  float spawnChance; // [0, 1] chance of adding a flamingo on tick
  float spawnRate; // flamingos per second (fps)
  int lastSpawnFromSpawnRate;
  
  int lastTick;
  int direction = 1;
  
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
    
    flamingos = new LinkedList<Target>();
  }
  
  void enterSubmode(int sm)
  {
    submode = sm;
    submodeStart = millis();
  }
  
  Target spawn(int direction, int startLife, boolean isCone)
  {
    Target t;
    if (isCone) {
      t = new Cone(direction, startLife);
    } else {
      t = new Flamingo(direction, startLife);
    }
    if (direction > 0) {
      t.x = -t.width();
    } else {
      t.x = displayWidth + t.width();
    }
    flamingos.addLast(t);
    return t;
  }
  
  Target spawnFromMode(int direction) {
  if (mode == FlamingoMode.ConesOnly) {
      return spawnCone(direction);
    } else {
      return spawnFlamingo(direction);
    }    
  }
  
  Cone spawnCone(int direction) {
    return (Cone)spawn(direction, 1, true);
  }
  
  Flamingo spawnFlamingo(int direction) {
    Flamingo f = (Flamingo)spawn(direction, 2, false);
    if (mode == FlamingoMode.Mess || mode == FlamingoMode.Parade) {
      f.usePauses = true;
    }
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
      case WhereAmI: {
        Flamingo f = spawnFlamingo(direction);
        f.swapHeadChance = 0;
        break;
      }
      case Parade:
        spawnRate = 4;
        spawnDuration = 4;
        break;
      case Mess:
        spawnDuration = 25;
        messPeak = 0.1;
        if (rand.nextFloat() < 0.3) {
          directionIsRandom = true;
        }
        break;
      case War:
        spawnDuration = 20;
        messPeak = 0.22;
        break;
      case Nyan: {
        Flamingo f = spawnFlamingo(direction);
        f.swapHeadChance = 0;
        f.speed = 0.5;
        
        bursts = new LinkedList<NyanBurst>();
        break;
      }
      case ConeDown: {
        Flamingo f = spawnFlamingo(direction);
        f.swapHeadChance = 0;
        Cone c = spawnCone(direction);
        c.x += direction * c.width();
        break;
      }
      case ConesOnly: {
        spawnRate = 1;
        break;
      }
    }
  }
  
  int randomDirection()
  {
    return (rand.nextBoolean() ? DirectionRight : DirectionLeft);
  }
  
  boolean warIsOngoing()
  {
    return mode == FlamingoMode.War && isInteracting();
  }
  
  // ----------------------- Public methods ---------------------- //
  
  public void startPattern()
  {
    direction = randomDirection();
    deathToll = 0;
    
    FlamingoMode m;
    do {
      m = randomEnum(FlamingoMode.class);
    } while (m == FlamingoMode.Test || m == FlamingoMode.War);
    
    //m = FlamingoMode.Nyan;
    
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
        if (warIsOngoing()) {
          // change sides, or from both sides!
          directionIsRandom = !directionIsRandom;
        } else {
          spawnChance = 0;
          spawnRate = 0;
          keepSpawning = false;
        }
      }
    }
    
    switch(mode) {
      case Test:
        break;
      case WhereAmI: {
        if (flamingos.size() > 0) {
          Flamingo f = (Flamingo)flamingos.getFirst();
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
      case War:
      case Mess:
        if (keepSpawning) {
          spawnChance = 0.5 * (1 + sin(spawnElapsed / (float)spawnDuration * 3.14159));
          spawnChance *= messPeak; // max density chance one flamingo ever 4 pixels
        }
        break;
      case ConesOnly: {
        final int kConeRuntime = 30 * 1000;
        if (isRunning() && runTime() > kConeRuntime) {
          spawnRate = 0;
        }
        if (isRunning() && runTime() > kConeRuntime + 6000) {
          lazyStop();
        }
        break;
      }
      case ConeDown: {
        if (flamingos.size() > 0) {
          Flamingo f = (Flamingo)flamingos.getFirst();
          Cone c = (flamingos.size() > 1 ? (Cone)flamingos.getLast() : null);
          if (submode == 0) {
            if (f.x == displayWidth / 2 + 12) {
              f.speed = 0;
              if (c != null) {
                c.life = 0;
              }
              enterSubmode(1);
            }
          } else if (submode == 1) {
            if (millis() - submodeStart > 1000) {
              f.sad = true;
            }
            if (millis() - submodeStart > 2000) {
              if (c != null) {
                c.checkForDeath();
              }
            }
            if (millis() - submodeStart > 4500) {
              enterSubmode(2);
            }
          } else if (submode == 2) {
            f.sad = false;
            f.speed = 1;
          }
        }
        break;
      }
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
        spawnFromMode(direction);
      }
      if (spawnAllowed && spawnRate > 0 && millis() - lastSpawnFromSpawnRate > 1/spawnRate * 1000) {
        spawnFromMode(direction);
        lastSpawnFromSpawnRate = millis();
      }
      
      Iterator<Target> it = flamingos.iterator();
      while (it.hasNext()) {
        Target target = it.next();
        target.tick();
        int nyanAddition = (mode == FlamingoMode.Nyan ? nyanWaveLength : 0);
        if (target.x + target.width() > displayWidth + 20 + nyanAddition || target.x < -20 - nyanAddition) {
          if (mode != FlamingoMode.Nyan) {
          }
          it.remove();
        }
        if (target.isDead()) {
          it.remove();
          deathToll++;
          if (deathToll > 2 && mode != FlamingoMode.War) {
            // Of course you realize this means war.
            startMode(FlamingoMode.War);
          }
        }
      }
      
      updateMode(tickMillis);
    }
    
    for (Target flamingo : flamingos) {
      flamingo.drawTarget();
      
      if (mode == FlamingoMode.Nyan) {
        drawRainbowTail(flamingo);
      }
    }
    
    if (flamingos.size() == 0 && mode != FlamingoMode.Test) {
      if (this.isStopping()) {
        this.stopCompleted();
      } else {
        if (mode == FlamingoMode.WhereAmI && isRunning() && rand.nextFloat() < 0.3) {
          // 30% chance of getting chased by a parade
          startMode(FlamingoMode.Parade);
        } else if (isRunning() && millis() - modeStart > 5000 && !warIsOngoing()) {
          // no flamingos and we've been running for more than 5 seconds as a sanity check 
          println("Stopping flamingos because we've run out of flamingos");
          lazyStop();
        }
      }
    }
  }
  
  boolean wantsInteraction()
  {
    return flamingos.size() > 0;
  }
  
  boolean wantsToIdleStop()
  {
    return false;
  }
  
  private LinkedList<NyanBurst> bursts;
  private int nyanWaveLength = 45; // 15 * 3
  
  void drawRainbowTail(Target f) {
    noFill();
    colorMode(HSB, 100);
    
    pushMatrix();
    
    translate(f.x, 0, 0);
    scale(direction, 1, 1);
    if (direction == DirectionLeft) {
      translate(-flamingoWidth, 0, 0);
    }
    
    int waveLength = 15;
    for (int wave = 0; wave < waveLength; ++wave) {
      int segs = displayHeight - 1;
      for (int i = 0; i < segs; ++i) {
        stroke((i * 100 / segs) % 100, 100, 50, 100 - 100 * wave / (float)waveLength);
        int x = -3 * wave;
        int y = i + 1 + (int)(f.x/2.0 + wave) % 2;
        line(x, y, x - 3, y);
      }
    }
    
    Iterator<NyanBurst> it = bursts.iterator();
    while (it.hasNext()) {
      NyanBurst b = it.next();
      b.tick();
      if (b.isDone()) {
        it.remove();
      }
    }
    if (f.x % 2 == 0) {
      bursts.addLast(new NyanBurst());
    }
    for (NyanBurst b : bursts) {
      b.draw();
    }
   
    popMatrix();
  }
}

class NyanBurst {
  float x;
  int y;
  float progress;
  int state;
  
  NyanBurst() {
    x = flamingoWidth + rand.nextInt() % 20 - 10 + 20;
    y = rand.nextInt() % displayHeight;
  }
  
  void tick() {
    progress += 1;
    state = (int)progress / 8;
    x -= 0.5;
  }
  
  boolean isDone() {
    return state > 3;
  }
  
  void draw() {
    pushMatrix();
    translate((int)x, y, 0);
    colorMode(RGB, 100);
    blendMode(ADD);
    stroke(100, 100, 100);
    
    switch (state) {
      case 0:
        point(0, 0);
        break;
      case 1:
        point(0, 1);
        point(1, 0);
        point(0, -1);
        point(-1, 0);
        break;
      case 2:
        stroke(100, 100, 100, 50);
        //point(0, 0);
        point(0, 2);
        point(1, 1);
        point(2, 0);
        point(-1, 1);
        point(0, -2);
        point(-1, -1);
        point(-2, 0);
        point(1, -1);
        break;
      case 3:
        stroke(100, 100, 100, 20);
        //point(0, 1);
        //point(1, 0);
        //point(0, -1);
        //point(-1, 0);
        
        point(0, 3);
        point(2, 2);
        point(3, 0);
        point(-2, 2);
        point(0, -3);
        point(-2, -2);
        point(-3, 0);
        point(2, -2);

        break;
    }
    popMatrix();
  }
}