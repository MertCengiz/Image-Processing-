static PImage originalImage;
final static float SIGMA = 10;
final static int KERNELSIZE = 5;
final static int HALFWINDOWSIZE = ((5 * KERNELSIZE) / 2);

void setup(){
  try{
    originalImage = loadImage(args[0]);
    if (args == null || args.length != 1 || originalImage == null){
      println("Hatali arguman girisi. Tekrar deneyin.");
      exit();
      return;
    }
  }
  catch(Exception e){
    println("Hatali arguman girisi. Tekrar deneyin.");
    exit();
    return;
  }  
  image(originalImage, 0, 0);
  textSize(30);
  fill(200,100,50);
  text("Orijinal Görüntü", 0, originalImage.height + 40);

  noLoop();
}

void draw(){
  PImage colouredDenoised = createImage(originalImage.width, originalImage.height, RGB);
  colouredDenoised = colouredNLM(originalImage, colouredDenoised);
  colouredDenoised.save("Gürültüsüz_" + args[0]);
  exit();
}

float calculateEuclidianDistance(int sourceI, int sourceJ, int destinationI, int destinationJ){
  float distance = dist(sourceI, sourceJ, destinationI, destinationJ);
  distance = distance * sq(KERNELSIZE);
  return distance;
}

PImage colouredNLM(PImage sourceImage, PImage destinationImage){
  for(int x = 0; x < sourceImage.width; x++){
    for(int y = 0; y < sourceImage.height; y++){      
      
      float totalWeight = 0;
      float redSum = 0;
      float greenSum = 0;
      float blueSum = 0;
      
      // For each pixel, iterate all pixels in the search window and calculate weights.
      
      for(int i = (x - HALFWINDOWSIZE); i < (x + HALFWINDOWSIZE); i++){  
        for(int j = (y - HALFWINDOWSIZE); j < (y + HALFWINDOWSIZE); j++){
          if (x == i && y == j)
            continue;
          float totalDistance = calculateEuclidianDistance(x, y, i, j);
          float weight = exp(- totalDistance / sq(SIGMA));
          
          totalWeight += weight;
          
          // Imagine a black pad outside of an image. In this case, "red", "green" and "blue" values would be zero (no contribution to sums)
          
          if (i >= 0 && j >= 0 && i <= sourceImage.width && j <= sourceImage.height){  
            color pixelValue = sourceImage.get(i, j);
            float red = (pixelValue >> 16) & 0xFF;
            float green = (pixelValue >> 8) & 0xFF;
            float blue = pixelValue & 0xFF;
            redSum += weight * red;
            greenSum += weight * green;
            blueSum += weight * blue;
          }
        }
      }
      color newColor = color((int)(redSum / totalWeight), (int)(greenSum / totalWeight), (int)(blueSum / totalWeight));  // Take average
      destinationImage.pixels[x + y * destinationImage.width] = newColor;
    }
  }
  return destinationImage;
}
