import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  TextRecognizer? _textRecognizer;
  TextRecognitionScript _currentScript = TextRecognitionScript.latin;

  void setScript(TextRecognitionScript script) {
    if (_currentScript == script && _textRecognizer != null) return;
    _textRecognizer?.close();
    _currentScript = script;
    _textRecognizer = TextRecognizer(script: script);
  }

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer(script: _currentScript);
    return _textRecognizer!;
  }

  /// Recognize text from an image file path.
  Future<String> recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _recognizer.processImage(inputImage);
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
      return await _recognizer.processImage(inputImage);
    } catch (e) {
      debugPrint('OCR structured error: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer?.close();
  }

  /// Available scripts with display names.
  static const Map<TextRecognitionScript, String> supportedScripts = {
    TextRecognitionScript.latin: 'English / Latin',
    TextRecognitionScript.korean: '한국어',
    TextRecognitionScript.japanese: '日本語',
    TextRecognitionScript.chinese: '中文',
    TextRecognitionScript.devanagari: 'हिन्दी',
  };

  static TextRecognitionScript scriptFromName(String name) {
    switch (name) {
      case 'korean': return TextRecognitionScript.korean;
      case 'japanese': return TextRecognitionScript.japanese;
      case 'chinese': return TextRecognitionScript.chinese;
      case 'devanagari': return TextRecognitionScript.devanagari;
      default: return TextRecognitionScript.latin;
    }
  }

  static String scriptToName(TextRecognitionScript script) {
    switch (script) {
      case TextRecognitionScript.korean: return 'korean';
      case TextRecognitionScript.japanese: return 'japanese';
      case TextRecognitionScript.chinese: return 'chinese';
      case TextRecognitionScript.devanagari: return 'devanagari';
      default: return 'latin';
    }
  }
}
