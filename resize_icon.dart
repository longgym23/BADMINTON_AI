import 'dart:io';
import 'package:image/image.dart' as img;

void processImage(String path, String outputPath) {
  final file = File(path);
  if (!file.existsSync()) {
    print('File not found: $path');
    return;
  }
  
  final image = img.decodeImage(file.readAsBytesSync());
  if (image == null) {
    print('Failed to decode image: $path');
    return;
  }
  
  // Find bounding box of non-transparent pixels
  int minX = image.width;
  int minY = image.height;
  int maxX = 0;
  int maxY = 0;
  
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.a > 0) { // Not fully transparent
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }
  
  print('Original size: ${image.width}x${image.height}');
  print('Bounding box: $minX, $minY to $maxX, $maxY');
  
  if (minX > maxX || minY > maxY) {
    print('Image is fully transparent!');
    return;
  }
  
  final cropWidth = maxX - minX + 1;
  final cropHeight = maxY - minY + 1;
  
  final cropped = img.copyCrop(image, x: minX, y: minY, width: cropWidth, height: cropHeight);
  
  // Create a new square image with a bit of padding (e.g., 5-10% padding so it's not strictly edge-to-edge)
  // But wait, adaptive icon foregrounds usually look better when they fill around 60-70% of the space.
  // The user says the logo is "quá bé và bị xấu" (too small and ugly).
  // So let's make it fill about 85% of the frame.
  
  int maxDim = cropWidth > cropHeight ? cropWidth : cropHeight;
  int newDim = (maxDim / 0.85).round();
  
  final outImage = img.Image(width: newDim, height: newDim, numChannels: 4);
  
  // Fill with transparent
  for (int y = 0; y < newDim; y++) {
    for (int x = 0; x < newDim; x++) {
      outImage.setPixelRgba(x, y, 0, 0, 0, 0);
    }
  }
  
  // Center the cropped image inside the new padded square
  int dstX = (newDim - cropWidth) ~/ 2;
  int dstY = (newDim - cropHeight) ~/ 2;
  
  img.compositeImage(outImage, cropped, dstX: dstX, dstY: dstY);
  
  File(outputPath).writeAsBytesSync(img.encodePng(outImage));
  print('Saved $outputPath with size ${newDim}x${newDim}');
}

void main() {
  processImage('assets/images/logo1_android.png', 'assets/images/logo1_android_large.png');
  processImage('assets/images/logo1_ios.png', 'assets/images/logo1_ios_large.png');
}
