import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Recognize text from an image file path.
  /// Returns recognized text as a single string, or empty string on failure.
  Future<String> recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('OCR error: $e');
      return '';
    }
  }

  /// Recognize text and return structured blocks for overlay rendering.
  Future<RecognizedText?> recognizeTextStructured(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      return await _textRecognizer.processImage(inputImage);
    } catch (e) {
      debugPrint('OCR structured error: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
