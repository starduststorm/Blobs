
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

private class Flamingo {
  int x;
  int bodyPose;
  int legPose;
  int direction;
  
  public Flamingo(int d)
  {
    this.direction = d;
    legPose = rand.nextInt(legImages.length);
    bodyPose = rand.nextInt(bodyImages.length);
  }
  
  public void tick()
  {
    // preen
    if (rand.nextInt(10) == 0) {
      bodyPose = rand.nextInt(bodyImages.length);
    }
    
    // may pause
    if (rand.nextInt(100) > 0) {
      x += direction;
      legPose = (legPose + 1) % legImages.length;
    }
  }
  
  public void draw()
  {
    blendMode(BLEND);
    PImage bodyImg = bodyImages[this.bodyPose];
    PImage legsImg = legImages[this.legPose];
    //tint(100, 50);
    
    pushMatrix();
    translate(x, 0, 0);
    scale(direction, 1, 1);
    
    image(bodyImg, 0, 0);
    image(legsImg, 1, bodyImg.height);
    popMatrix();
  }
}

// ------------------------------------------------------- //

public class FlamingoPattern extends IdlePattern
{
  private LinkedList<Flamingo> flamingos;
  int lastTick;
  int lastAdd;
  int direction;
  final int justhowdamnbigtheparadeis = 20;
  
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
  
  public void startParade()
  {
    direction = (rand.nextBoolean() ? 1 : -1);
    //for (int i = 0; i < justhowdamnbigtheparadeis; ++i) {
    //  Flamingo f = new Flamingo(direction);
    //  f.x = (direction < 0 ? displayWidth : 0);
    //  f.x -= direction * (i * flamingoWidth - 2 + rand.nextInt(15));
    //  flamingos.addLast(f);
    //}
  }
  
  public void startPattern()
  {
    super.startPattern();
    startParade();
  }
  
  public void update()
  {
    final float frametime = 1000/30.0;
    
    if (flamingos.size() < justhowdamnbigtheparadeis) {
      if (millis() - lastAdd > flamingoWidth * frametime) {
        lastAdd = (int)(millis() - 2 + frametime * rand.nextInt(12));

        Flamingo f = new Flamingo(direction);
        if (direction > 0) {
          f.x = -flamingoWidth;
        } else {
          f.x = displayWidth + flamingoWidth;
        }
        flamingos.addLast(f);
        println("now have " + flamingos.size() + " flamingos");
      }
    }
    
    if (millis() - lastTick > frametime) {
      lastTick = millis();
      
      Iterator<Flamingo> it = flamingos.iterator();
      while (it.hasNext()) {
        Flamingo flamingo = it.next();
        flamingo.tick();
        if (flamingo.x + flamingoWidth > displayWidth + 20 || flamingo.x < -20) {
          it.remove();
        }
      }
    }
    for (Flamingo flamingo : flamingos) {
      flamingo.draw();
    }
  }
}