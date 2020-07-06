//based on this site https://www.youtube.com/watch?v=eaXk97ujbPQ

int pSize = 2;//5
float hMult = 400;//1000
float scale = 200;//100 noise scale

Terrain terrain;

void setup(){
  //fullScreen(P3D);
  size(1000, 700, P3D);
  terrain = new Terrain(0);
}

void keyPressed(){
  if(key=='r'){
    terrain = new Terrain(random(10));
  }
}

void draw(){
  background(255);
  translate(0, height/2, -height/2);
  rotateX(radians(60));
  lights();
  noStroke();
  terrain.show();
  terrain.erode(7000);
}
