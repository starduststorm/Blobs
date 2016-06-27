public class Blobby
{
  color blobbyColor;
  float x, y;
  float dx;
  float initialX;
  
  public Blobby(PVector p, color c, float dx)
  {
    //println("Made blobby " + p + ", dx = " + dx);
    this.x = p.x;
    this.y = p.y;
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