public enum BlobbyType {
  Blobby, Liney, Splody,
};

public class Blobby
{
  color blobbyColor;
  PVector position;
  PVector velocity;
  BlobbyType type;
  boolean impacted;
  
  public Blobby(PVector start, PVector velocity, color c, BlobbyType type)
  {
    //println("Made blobby " + p + ", dx = " + dx);
    this.position = start;
    this.blobbyColor = c;
    this.velocity = velocity;
    this.type = type;
  }
  
  public void update()
  {
    this.position.add(this.velocity);
    if (this.type == BlobbyType.Splody) {
      // fall
      this.velocity.y += 0.05;
    }
  }
  
  public void impact()
  {
    // we hit something
    impacted = true;
  }
  
  public boolean isDead()
  {
    if (impacted) {
      return true;
    }
    
    switch (type) {
      case Liney:
      case Splody:
        return this.position.y > blobsRegionHeight + 1;
      case Blobby:
      default:
        return this.position.x < 0 || this.position.x > blobsRegionWidth;
    }
  }
  
  public void draw()
  {
    if (impacted) {
      return;
    }
    
    blendMode(BLEND);
    colorMode(RGB, 100);
    color c = this.blobbyColor;
    
    switch (type) {
      case Liney: {
        stroke(red(c), green(c), blue(c), 60);
        noFill();
        float x = round(this.position.x) + 0.5; 
        this.position.y = sin(this.position.x / 12.0) * blobsRegionHeight / 2.0 + blobsRegionHeight / 2.0;
        line(x, this.position.y, x, blobsRegionHeight + 1);
        break;
      }
      
      case Splody: {
        fill(red(c), green(c), blue(c), 50);
        final float radius = 2;
        ellipse(this.position.x, this.position.y, radius, radius);
        break;
      }
      
      case Blobby: {
        noStroke();
        fill(red(c), green(c), blue(c), 60);
        final float radius = 3;
        ellipse(this.position.x, this.position.y, radius, radius);
        break;
      }
      default: break;
    }
  }
}