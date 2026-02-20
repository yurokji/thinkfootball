import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:docushot/data/services/ocr_service.dart';

void main() {
  group('OcrService', () {
    test('scriptFromName returns correct script', () {
      expect(OcrService.scriptFromName('latin'), TextRecognitionScript.latin);
      expect(OcrService.scriptFromName('korean'), TextRecognitionScript.korean);
      expect(OcrService.scriptFromName('japanese'), TextRecognitionScript.japanese);
      expect(OcrService.scriptFromName('chinese'), TextRecognitionScript.chinese);
      expect(OcrService.scriptFromName('devanagari'), TextRecognitionScript.devanagari);
      expect(OcrService.scriptFromName('unknown'), TextRecognitionScript.latin);
    });

    test('scriptToName returns correct string', () {
      expect(OcrService.scriptToName(TextRecognitionScript.latin), 'latin');
      expect(OcrService.scriptToName(TextRecognitionScript.korean), 'korean');
      expect(OcrService.scriptToName(TextRecognitionScript.japanese), 'japanese');
      expect(OcrService.scriptToName(TextRecognitionScript.chinese), 'chinese');
      expect(OcrService.scriptToName(TextRecognitionScript.devanagari), 'devanagari');
    });

    test('supportedScripts contains all 5 languages', () {
      expect(OcrService.supportedScripts.length, 5);
      expect(OcrService.supportedScripts.containsKey(TextRecognitionScript.korean), true);
      expect(OcrService.supportedScripts.containsKey(TextRecognitionScript.latin), true);
    });

    test('round-trip name conversion', () {
      for (var entry in OcrService.supportedScripts.entries) {
        final name = OcrService.scriptToName(entry.key);
        final script = OcrService.scriptFromName(name);
        expect(script, entry.key);
      }
    });
  });
}
