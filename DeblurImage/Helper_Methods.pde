

float[][][] normalizeZeroOne(float[][][] image){
  for (int i = 0; i < image.length; i++){
    for(int j = 0; j < image[i].length; j++){
      image[i][j][0] /= 255;   
      image[i][j][1] /= 255;  
      image[i][j][2] /= 255;  
    }
  }
  return image;
}

float[][][] denormalize(float[][][] image){
  for (int i = 0; i < image.length; i++){
    for(int j = 0; j < image[i].length; j++){
      image[i][j][0] *= 255;   
      image[i][j][1] *= 255; 
      image[i][j][2] *= 255; 
    }
  }
  return image;
}

float[][][] convolveEstimatedImage(float[][][] estimatedImage, float[][] estimatedPSF) {
  float[][][] resultImage = new float[estimatedImage.length][estimatedImage[0].length][3];
  for (int x = 0; x < estimatedImage.length; x++) {
    for (int y = 0; y < estimatedImage[0].length; y++) {
      float redEstimatedValue = 0;
      float greenEstimatedValue = 0;
      float blueEstimatedValue = 0;
      for (int i = 0; i < estimatedPSF.length; i++) {
        for (int j = 0; j < estimatedPSF[0].length; j++) {
          int xCoor = x - estimatedPSF.length / 2 + i;
          int yCoor = y - estimatedPSF[0].length / 2 + j;
          // Check if the current pixel is within the bounds of the image.
          if (xCoor >= 0 && xCoor < estimatedImage.length && yCoor >= 0 && yCoor < estimatedImage[0].length) {
            redEstimatedValue += estimatedImage[xCoor][yCoor][0] * estimatedPSF[i][j];
            greenEstimatedValue += estimatedImage[xCoor][yCoor][1] * estimatedPSF[i][j];
            blueEstimatedValue += estimatedImage[xCoor][yCoor][2] * estimatedPSF[i][j];
          }
          else {  // White padding.
            redEstimatedValue += estimatedPSF[i][j];
            greenEstimatedValue += estimatedPSF[i][j];
            blueEstimatedValue += estimatedPSF[i][j];
          }
        }
      }
      resultImage[x][y][0] = redEstimatedValue;
      resultImage[x][y][1] = greenEstimatedValue;
      resultImage[x][y][2] = blueEstimatedValue;
    }
  }
  return resultImage;
}

float[][][] findResiduals(float[][][] estimatedImage, PImage sourceImage) {
  float[][][] residuals = new float[sourceImage.width][sourceImage.height][3];
  for (int x = 0; x < estimatedImage.length; x++) {
    for (int y = 0; y < estimatedImage[0].length; y++) {
      // Check if the current pixel is within the bounds of the source image.
      if (x < sourceImage.width && y < sourceImage.height) {
        float redResidual = (red(sourceImage.pixels[x + y * sourceImage.width]) / 255) / (estimatedImage[x][y][0] + 1e-6);
        float greenResidual = (green(sourceImage.pixels[x + y * sourceImage.width]) / 255) / (estimatedImage[x][y][1] + 1e-6);
        float blueResidual = (blue(sourceImage.pixels[x + y * sourceImage.width]) / 255) / (estimatedImage[x][y][2] + 1e-6);
        residuals[x][y][0] = redResidual;
        residuals[x][y][1] = greenResidual;
        residuals[x][y][2] = blueResidual;
      }
      else{  // Handle pixels outside the source image's bounds (e.g., set residuals to zero).
        residuals[x][y][0] = 0;
        residuals[x][y][1] = 0;
        residuals[x][y][2] = 0;
      }
    }
  }
  return residuals;
}

float[][] updateNormalizePSF(float[][] estimatedPSF, float[][][] estimatedImage, float[][][] residuals) {
  float psfUpdateSumNom = 0;
  float psfUpdateSumDenom = 0;
  
  for (int x = 0; x < estimatedImage.length; x++) {
    for (int y = 0; y < estimatedImage[x].length; y++) {
      float residualAverage = ((residuals[x][y][0] + residuals[x][y][1] + residuals[x][y][2]) / 3);
      float estimatedAverage = ((estimatedImage[x][y][0] + estimatedImage[x][y][1] + estimatedImage[x][y][2]) / 3);
      psfUpdateSumNom += residualAverage * estimatedAverage;
      psfUpdateSumDenom += estimatedAverage;      
    }
  }
  // Update the PSF.
  float psfUpdateValue = psfUpdateSumNom / psfUpdateSumDenom;
  float updatedPSFSum = 0;
 
  for (int x = 0; x < estimatedPSF.length; x++) {
    for (int y = 0; y < estimatedPSF[0].length; y++) {
      estimatedPSF[x][y] *= psfUpdateValue;
      updatedPSFSum += estimatedPSF[x][y];
    }
  }

  // Normalize the PSF so that it sums to 1.
  for (int x = 0; x < estimatedPSF.length; x++) {
    for (int y = 0; y < estimatedPSF[0].length; y++) 
      estimatedPSF[x][y] /= updatedPSFSum;    
  }
  return estimatedPSF;
}

float[][][] updateEstimatedImage(float[][][] estimatedImage, float[][] psf, float[][][] residual) {
  float[][][] updatedImage = new float[estimatedImage.length][estimatedImage[0].length][3];

  for (int i = 0; i < estimatedImage.length; i++) {
    for (int j = 0; j < estimatedImage[0].length; j++) {
      float redCorrectionFactor = 0;
      float greenCorrectionFactor = 0;
      float blueCorrectionFactor = 0;
      for (int k = 0; k < psf.length; k++) {
        for (int l = 0; l < psf[0].length; l++) {
          int x = i + k - psf.length / 2;  // Adjust for PSF center
          int y = j + l - psf[0].length / 2;  // Adjust for PSF center
          if (x >= 0 && x < estimatedImage.length && y >= 0 && y < estimatedImage[0].length) {
            redCorrectionFactor += psf[k][l] * estimatedImage[x][y][0];
            greenCorrectionFactor += psf[k][l] * estimatedImage[x][y][1];
            blueCorrectionFactor += psf[k][l] * estimatedImage[x][y][2];
          }
        }
      }
      updatedImage[i][j][0] = estimatedImage[i][j][0] * (residual[i][j][0] / (redCorrectionFactor + 1e-10));
      updatedImage[i][j][1] = estimatedImage[i][j][1] * (residual[i][j][1] / (greenCorrectionFactor + 1e-10));
      updatedImage[i][j][2] = estimatedImage[i][j][2] * (residual[i][j][2] / (blueCorrectionFactor + 1e-10));
      
      updatedImage[i][j][0] = constrain(updatedImage[i][j][0], 1e-10, 1);
      updatedImage[i][j][1] = constrain(updatedImage[i][j][1], 1e-10, 1);
      updatedImage[i][j][2] = constrain(updatedImage[i][j][2], 1e-10, 1);
    }
  }
  return updatedImage;
}
