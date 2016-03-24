public class Blobby
{
  color blobbyColor;
  float x, y;
  float dx;
  float initialX;
  
  public Blobby(float x, color c, float dx)
  {
    println("Made blobby " + x + ", dx = " + dx);
    this.x = x;
    this.y = height / 2 + random(-2, 2);
    this.blobbyColor = c;
    this.dx = dx;
    this.initialX = x;
  }
  
  public void update()
  {
    this.x += this.dx;
  }
  
  public void draw()
  {
    blendMode(BLEND);
    colorMode(RGB, 100);
    noStroke();
    
    color c = this.blobbyColor;
    fill(red(c), green(c), blue(c), 60);
    float radius = 3;
    ellipse(x, y, radius, radius);
  }
}