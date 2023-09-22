static PImage originalImage;
final static int TOTALITERATIONS = 50;

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
  loadPixels();
  
  PImage colouredDeblurred = createImage(originalImage.width, originalImage.height, RGB);  
  colouredDeblurred = colouredDeconvolve(originalImage, colouredDeblurred);
  
  updatePixels();
  
  colouredDeblurred.save("Blursuz_" + args[0]);
  exit();
}

PImage colouredDeconvolve(PImage sourceImage, PImage destinationImage){
  float[][][] estimatedImage = new float[sourceImage.width][sourceImage.height][3];

  for (int i = 0; i < sourceImage.width; i++){
    for (int j = 0; j < sourceImage.height; j++){
      estimatedImage[i][j][0] = red(sourceImage.pixels[i + j * sourceImage.width]);
      estimatedImage[i][j][1] = green(sourceImage.pixels[i + j * sourceImage.width]);
      estimatedImage[i][j][2] = blue(sourceImage.pixels[i + j * sourceImage.width]);
    }
  } 
  
  estimatedImage = normalizeZeroOne(estimatedImage);
  
  float[][] estimatedPSF = {{0.0039, 0.0156, 0.0234, 0.0156, 0.0039},
                            {0.0156, 0.0625, 0.0937, 0.0625, 0.0156},
                            {0.0234, 0.0937, 0.1406, 0.0937, 0.0234},
                            {0.0156, 0.0625, 0.0937, 0.0625, 0.0156},
                            {0.0039, 0.0156, 0.0234, 0.0156, 0.0039}};
                            
  for (int iteration = 0; iteration < TOTALITERATIONS; iteration++) {       
    // Convolve the estimated image with the estimated PSF.
    float[][][] convolvedImage = convolveEstimatedImage(estimatedImage, estimatedPSF);
    
    // Calculate residuals.
    float[][][] residuals = findResiduals(convolvedImage, sourceImage);    
    
    // Update and normalize the PSF.
    estimatedPSF = updateNormalizePSF(estimatedPSF, convolvedImage, residuals);
    // Update the estimated image while checking for pixel value constraints.
    estimatedImage = updateEstimatedImage(estimatedImage, estimatedPSF, residuals);     

  }
  
  estimatedImage = denormalize(estimatedImage);
  
  for (int i = 0; i < destinationImage.width; i++){
    for (int j = 0; j < destinationImage.height; j++)
      destinationImage.pixels[i + j * destinationImage.width] = color(round(estimatedImage[i][j][0]), round(estimatedImage[i][j][1]), round(estimatedImage[i][j][2]));
  }
  return destinationImage;
}
