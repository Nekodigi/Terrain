class Terrain{
  
  int maxDropletLifetime = 30;
  float depositSpeed = .3;
  float inertia = .05;//At zero. water will instantly change direction to flow downhill. At 1, water will never change direction.
  float sedimentCapaFac = 4;// Multiplier for how much sediment a droplet can carry
  float minSedimentCapa = .01;// Used to prevent carry capacity getting too close to zero on flatter terrain
  float initWaterVolume = 1;
  float initSpeed = 1;
  float erodeSpeed = .3;
  int erosionRadius = 3;
  float gravity = 4;
  float evaporateSpeed = .01;
  
  float[][] map;
  Index[][][] erosionBrushIndices;
  float[][][] erosionBrushWeights;
  int w, h;
  
  Terrain(float zoff){
    w = width/pSize;
    h = height/pSize;
    map = new float[w][h];
    float minValue = Float.POSITIVE_INFINITY;
    float maxValue = Float.NEGATIVE_INFINITY;
    for(int j = 0; j < h; j++){
      for(int i = 0; i < w; i++){
        float value = noise(i/scale, j/scale, zoff);
        map[i][j] = value;
        minValue = min(minValue, value);
        maxValue = max(maxValue, value);
      }
    }
    //Normalize
    for(int j = 0; j < h; j++){
      for(int i = 0; i < w; i++){
        map[i][j] = map(map[i][j], minValue, maxValue, 0, 1);
      }
    }
    initBrushIndices();
  }
  
  void erode(int numIter){
    for(int _iter = 0; _iter < numIter; _iter++){
      //create droplet
      float posX = random(w-1);
      float posY = random(h-1);
      float dirX = 0;
      float dirY = 0;
      float speed = initSpeed;
      float water = initWaterVolume;
      float sediment = 0;
      for(int _lifeT = 0; _lifeT < maxDropletLifetime; _lifeT++){
        //update droplet
        int nodeX = (int)posX;
        int nodeY = (int)posY;
        float offX = posX - nodeX;
        float offY = posY - nodeY;
        //get height and gradient
        HeightAndGrad heightGrad = calcHeightAndGrad(posX, posY);
        //The direction in which the droplet moves
        dirX = dirX*inertia - heightGrad.gradX*(1-inertia);
        dirY = dirY*inertia - heightGrad.gradY*(1-inertia);
        //Normalize direction
        float len = sqrt(dirX*dirX+dirY*dirY);
        if(len != 0){
          dirX /= len;
          dirY /= len;
        }
        posX += dirX;
        posY += dirY;
        //Stop simulation if it's not moving of flowed over edge of map.
        if((dirX == 0 & dirY == 0) || posX < 0 || posX >= w-1 || posY < 0 || posY >= h-1){
          break;
        }
        
        //get height at new position and calculate the deltaHeight
        float newHeight = calcHeightAndGrad(posX, posY).hei;
        float deltaHeight = newHeight - heightGrad.hei;
        //higher when moving fast down a slope and contains lot of water;
        float sedimentCapacity = max(-deltaHeight*speed*water*sedimentCapaFac, minSedimentCapa);
        
        //If carry more sediment than capacity, of if flowing uphill
        if(sediment > sedimentCapacity || deltaHeight > 0){
          // If moving uphill (deltaHeight > 0) try fill up to the current height(allways sediment>amountToDeposit), otherwise deposit a fraction of the excess sediment
          float amountToDeposit = (deltaHeight > 0) ? min(deltaHeight, sediment) : (sediment - sedimentCapacity) * depositSpeed;
          sediment -= amountToDeposit;
          //add sediment to the four nodes of the current cell using bilinear interpolation
          map[nodeX][nodeY] += amountToDeposit*(1-offX)*(1-offY);
          map[nodeX+1][nodeY] += amountToDeposit*offX*(1-offY);
          map[nodeX][nodeY+1] += amountToDeposit*(1-offX)*offY;
          map[nodeX+1][nodeY+1] += amountToDeposit*offX*offY;
        }else{
          //Erode a function of the droplet's current carry capacity.
          //Clamp the erosion to the change in height so that it doesn't dig a hole in the terrain behind the doroplet
          float amountToErode = min((sedimentCapacity - sediment)*erodeSpeed, -deltaHeight);
          
          for(int i = 0; i < erosionBrushIndices[nodeX][nodeY].length; i++){
            Index target = erosionBrushIndices[nodeX][nodeY][i];
            float weightedErodeAmount = amountToErode*erosionBrushWeights[nodeX][nodeY][i];
            float deltaSediment = (map[target.i][target.j] < weightedErodeAmount) ? map[target.i][target.j] : weightedErodeAmount;
            map[target.i][target.j] -= deltaSediment;
            sediment += deltaSediment;
          }
        }
        //update droplet's speed and water content
        speed = sqrt(speed*speed+deltaHeight*gravity);
        water *= (1 - evaporateSpeed);
      }
    }
  }
  
  HeightAndGrad calcHeightAndGrad(float posX, float posY){
    int nodeX = (int)posX;
    int nodeY = (int)posY;
    float offX = posX - nodeX;
    float offY = posY - nodeY;
    //node's height data surround droplet
    float NW = map[nodeX][nodeY];
    float NE = map[nodeX+1][nodeY];
    float SW = map[nodeX][nodeY+1];
    float SE = map[nodeX+1][nodeY+1];
    //calc droplet's data using bilinear interpolation surround node.
    float hei = NW*(1-offX)*(1-offY)+NE*offX*(1-offY)+SW*(1-offX)*offY+SE*offX*offY;
    float gradX = (NE - NW)*(1 - offY)+(SE - SW)*offY;
    float gradY = (SW - NW)*(1 - offX)+(SE - NE)*offX;
    return new HeightAndGrad(hei, gradX, gradY);
  }
  
  void initBrushIndices(){
    erosionBrushIndices = new Index[w][h][];
    erosionBrushWeights = new float[w][h][];
    
    Index[] offsets = new Index[erosionRadius*erosionRadius*4];
    float[] weights = new float[erosionRadius*erosionRadius*4];
    float weightSum = 0;
    int count = 0;
    
    for(int j = 0; j < h; j++){
      for(int i = 0; i < w; i++){
        if(j <= erosionRadius || j >= h - erosionRadius || i <= erosionRadius + 1 || i >= w - erosionRadius){  //I don't know why this can be used.
          weightSum = 0;
          count = 0;
          for(int y = -erosionRadius; y <= erosionRadius; y++){
            for(int x = -erosionRadius; x <= erosionRadius; x++){
              float sqrDist = x*x + y*y;
              if(sqrDist < erosionRadius*erosionRadius){
                int coordX = i+x;
                int coordY = j+y;
                
                if(coordX >= 0 && coordX < w && coordY >= 0 && coordY < h){
                  float weight = 1 - sqrt(sqrDist)/erosionRadius;
                  weightSum += weight;
                  weights[count] = weight;
                  offsets[count] = new Index(x, y);//can't replace
                  count++;
                }
              }
            }
          }
        }
        erosionBrushIndices[i][j] = new Index[count];
        erosionBrushWeights[i][j] = new float[count];
        for(int k = 0; k < count; k++){
          erosionBrushIndices[i][j][k] = new Index(offsets[k].i+i, offsets[k].j+j);
          erosionBrushWeights[i][j][k] = weights[k]/weightSum;
        }
      }
    }
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

class Index{
  int i, j;
  Index(int i, int j){
    this.i = i;
    this.j = j;
  }
}

class HeightAndGrad{
  float hei;
  float gradX;
  float gradY;
  HeightAndGrad(float hei, float gradX, float gradY){
    this.hei = hei;
    this.gradX = gradX;
    this.gradY = gradY;
  }
}