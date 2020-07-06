class Terrain{
  float[][] map;
  int w, h;
  
  Terrain(float zoff){
    w = width/pSize;
    h = height/pSize;
    map = new float[w][h];
    for(int j = 0; j < h; j++){
      for(int i = 0; i < w; i++){
        float value = noise(i/scale, j/scale, zoff);
        map[i][j] = value;
      }
    }
  }
  
  void moveEdge(float zoff){
    for(int j = 0; j < h; j++){
      for(int i = 0; i < w/10; i++){
        float fac  = map(i, 0, w/10, 1, 0);
        float value = noise(i/scale, j/scale, zoff)*fac+map[i][j]*(1-fac);
        map[i][j] = value;
      }
    }
  }
  
  void wind(){
    PVector dir = new PVector(1, 0);//wind direction
    for(int j = 1; j < h-1; j++){
      for(int i = 1; i < w-1; i++){
        float fac = map((i-w/2)*(i-w/2), 0, w*w/4, 0, 1);
        PVector grad =  getGrad(i, j).normalize();
        float angle = PVector.dot(grad, dir);
        map[i][j] -= angle*amp;
      }
    }
    map = blur(map, 2, blurFac);
  }
  
  PVector getGrad(int i, int j){
    float x = map[i+1][j] - map[i-1][j];
    float y = map[i][j+1] - map[i][j-1];
    return new PVector(x, y);
  }
  
  void show(){
    for(int j = 0; j < h; j++){
      beginShape(TRIANGLE_STRIP);
      for(int i = 0; i < w; i++){
        vertex(i*pSize, j*pSize, map[i][j]*hMult);
        if(j < h-1){
          vertex(i*pSize, j*pSize+pSize, map[i][j+1]*hMult);
        }
      }
      endShape();
    }
  }
}
