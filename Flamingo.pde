
String[][] body = { {"00000112",
                     "00000100",
                     "00110100",
                     "01111100",
                     "11111100"},
                  
                    {"00000112",
                     "00000100",
                     "00110100",
                     "01111100",
                     "11111100"}
                };

color[] bodyColors = {color(0,0,0), color(255,20,147), color(220, 106, 5)};

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

color[] legColors = {color(0,0,0), color(255,20,147), color(220, 106, 5)};

PImage legImages[] = null;

int bodyWidth = body[0][0].length();
int bodyHeight = body[0].length;

int legsWidth = legs[0][0].length();
int legsHeight = legs[0].length;

int flamingoWidth = max(bodyWidth, legsWidth);
int flamingoHeight = max(bodyHeight, legsHeight);

private PImage[] imagesForData(String[][] data, color[] colors)
{
  colorMode(RGB, 100);
  PImage images[] = new PImage[data.length];
  
  int imgWidth = data[0][0].length();
  int imgHeight = data[0].length;
  
  for (int poseIndex = 0; poseIndex < data.length; ++poseIndex) {
    String[] pose = data[poseIndex];
    PImage img = createImage(imgWidth, imgHeight, RGB);
    img.loadPixels();
    for (int lineNum = 0; lineNum < imgHeight; lineNum++) {
      String line = pose[lineNum];
      for (int chr = 0; chr < line.length(); ++chr) {
        char c = line.charAt(chr);
        int colorIndex = Character.getNumericValue(c);
        img.pixels[lineNum * imgWidth + chr] = bodyColors[colorIndex];
      }
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
  
  public Flamingo(int direction)
  {
    this.direction = direction;
    legPose = rand.nextInt(legImages.length);
    bodyPose = rand.nextInt(bodyImages.length);
  }
  
  public void tick()
  {
    x += direction;
    legPose = (legPose + 1) % legImages.length;
    if (rand.nextInt(10) == 0) {
      bodyPose = rand.nextInt(bodyImages.length);
    }
  }
  
  public void draw()
  {
    PImage bodyImg = bodyImages[this.bodyPose];
    PImage legsImg = bodyImages[this.bodyPose];
    image(bodyImg, x, 0);
    image(legsImg, x+1, bodyImg.height);
  }
}

// ------------------------------------------------------- //

public class FlamingoPattern extends IdlePattern
{
  private ArrayList<Flamingo> flamingos;
  int lastTick;
  
  public FlamingoPattern(int displayWidth, int displayHeight)
  {
    super(displayWidth, displayHeight);
    
    if (bodyImages == null) {
      bodyImages = imagesForData(body, bodyColors);
    }
    if (legImages == null) {
      legImages = imagesForData(legs, legColors);
    }
  }
  
  public void startPattern()
  {
    int direction = 1;//(rand.nextBoolean() ? 1 : -1);
    for (int i = 0; i < 5; ++i) {
      Flamingo f = new Flamingo(direction);
      f.x = 0 - i * (flamingoWidth + 2 + rand.nextInt(10));
      flamingos.add(f);
    }
  }
  
  public void update()
  {
    if (millis() - lastTick > 1000/30.0) {
      lastTick = millis();
      for (Flamingo flamingo : flamingos) {
        flamingo.tick();
        flamingo.draw();
      }
    }
  }
}