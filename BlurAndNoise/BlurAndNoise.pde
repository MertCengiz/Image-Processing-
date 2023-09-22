static PImage originalImage;
final static float SIGMA = 10;
final static int KERNELSIZE = 5;

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
  originalImage = loadImage(args[0]);
  image(originalImage, 0, 0);
  textSize(30);
  fill(200,100,50);
  text("Orijinal Görüntü", 0, originalImage.height + 40);

  noLoop();
}

void draw(){
  loadPixels();
  
  PImage colouredBlurred = createImage(originalImage.width, originalImage.height, RGB);
  PImage colouredNoisy = createImage(originalImage.width, originalImage.height, RGB);

  colouredBlurred = applyColouredBlur(originalImage, colouredBlurred);
  colouredNoisy = getColouredNoisyPixel(originalImage, colouredNoisy); 
  
  colouredBlurred.save("Blurlu_" + args[0]);
  colouredNoisy.save("Gürültlü_" + args[0]);
  
  exit();
}

float gaussianDistribution(int x, int y){
  float kernel = exp(-((x * x + y * y) / (2 * SIGMA))) / (2 * PI * SIGMA);
  return kernel;
}

PImage applyColouredBlur(PImage sourceImage, PImage destinationImage){
  for (int x = 0; x < sourceImage.width; x++){
    for (int y = 0; y < sourceImage.height; y++){
      float redSum = 0;
      float greenSum = 0;
      float blueSum = 0;
      float kernelSum = 0;
  
      for (int i = 0; i < KERNELSIZE; i++) {
        for (int j = 0; j < KERNELSIZE; j++) {
          float kernel = gaussianDistribution(i, j);
          kernelSum += kernel; 
      
          // Get the colour on that specific pixel.
          if ((y + j) < sourceImage.height && (x + i) <sourceImage.width) {
            color pixelColor = sourceImage.pixels[(x + i) + ((y + j) * sourceImage.width)];  
            redSum += red(pixelColor) * kernel;
            greenSum += green(pixelColor) * kernel;
            blueSum += blue(pixelColor) * kernel;
          }
          else{
            redSum += 255 * kernel;
            greenSum += 255 * kernel;
            blueSum += 255 * kernel;
          }
        }
      }

      // Normalize the result by dividing by the sum of kernel values (Discrete Fourier Transform)
      float normalizationFactor = 1.0 / kernelSum;
      int normalizedRed = (int)(redSum * normalizationFactor);
      int normalizedGreen = (int)(greenSum * normalizationFactor);
      int normalizedBlue = (int)(blueSum * normalizationFactor);
  
       destinationImage.pixels[x + y * destinationImage.width] = color(normalizedRed, normalizedGreen, normalizedBlue);
    }
  }
  
  return destinationImage;
}

PImage getColouredNoisyPixel(PImage sourceImage, PImage destinationImage){
  for(int x = 0; x < sourceImage.width; x++){
    for (int y = 0; y < sourceImage.height; y++){
      float noiseValue = randomGaussian() * 25;
      color pixelColour = sourceImage.pixels[x + y * sourceImage.width]; 
  
      float newRed = red(pixelColour) + noiseValue;
      float newGreen = green(pixelColour) + noiseValue;
      float newBlue = blue(pixelColour) + noiseValue;
  
      //Constrain the values so that it doesn't exceed below 0 or above 255.
  
      newRed = constrain(newRed, 0, 255);
      newGreen = constrain(newGreen, 0, 255);
      newBlue = constrain(newBlue, 0, 255);
  
      destinationImage.pixels[x + y * destinationImage.width] = color(newRed, newGreen, newBlue);
    }
  }
  
  return destinationImage;
}
