//based on this site https://www.youtube.com/watch?v=YiAtM4EpQ4U

int pSize = 5;//2
float hMult = 1500;//500
float scale = 100;//50 noise scale
float amp = 0.002;//0.002
float blurFac = 0.1;//0.1

Terrain terrain;

void setup(){
  fullScreen(P3D);
  //size(1000, 700, P3D);
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
  terrain.moveEdge(float(frameCount)/100);
  terrain.wind();//contains blur
}
