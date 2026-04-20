import 'dart:io';
import 'package:image/image.dart' as img;

void processImageWhiteBg(String path, String outputPath) {
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
  
  // Find bounding box of non-white pixels
  int minX = image.width;
  int minY = image.height;
  int maxX = 0;
  int maxY = 0;
  
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      // White is 255, 255, 255
      if (pixel.r < 250 || pixel.g < 250 || pixel.b < 250 || pixel.a < 255) { 
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }
  
  print('Original size: ${image.width}x${image.height}');
  print('Bounding box (non-white): $minX, $minY to $maxX, $maxY');
  
  if (minX > maxX || minY > maxY) {
    print('Image is fully white/transparent!');
    return;
  }
  
  final cropWidth = maxX - minX + 1;
  final cropHeight = maxY - minY + 1;
  
  final cropped = img.copyCrop(image, x: minX, y: minY, width: cropWidth, height: cropHeight);
  
  // Create a new square image with 85% fill ratio, white background
  int maxDim = cropWidth > cropHeight ? cropWidth : cropHeight;
  int newDim = (maxDim / 0.85).round();
  
  final outImage = img.Image(width: newDim, height: newDim, numChannels: 4);
  
  // Fill with white
  for (int y = 0; y < newDim; y++) {
    for (int x = 0; x < newDim; x++) {
      outImage.setPixelRgba(x, y, 255, 255, 255, 255);
    }
  }
  
  int dstX = (newDim - cropWidth) ~/ 2;
  int dstY = (newDim - cropHeight) ~/ 2;
  
  img.compositeImage(outImage, cropped, dstX: dstX, dstY: dstY);
  
  File(outputPath).writeAsBytesSync(img.encodePng(outImage));
  print('Saved $outputPath with size ${newDim}x${newDim}');
}

void main() {
  processImageWhiteBg('assets/images/logo1_ios.png', 'assets/images/logo1_ios_large.png');
}
