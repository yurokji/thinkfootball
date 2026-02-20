import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class PdfService {
  Future<String> generatePdf(List<String> imagePaths, String title) async {
    final pdf = pw.Document();

    for (var imagePath in imagePaths) {
      final file = File(imagePath);
      if (!await file.exists()) continue;

      final bytes = file.readAsBytesSync();
      final image = pw.MemoryImage(bytes);

      // Determine page format from image aspect ratio
      final decoded = img.decodeImage(bytes);
      PdfPageFormat format = PdfPageFormat.a4;

      if (decoded != null) {
        final imgRatio = decoded.width / decoded.height;
        if (imgRatio > 1.0) {
          // Landscape image -> landscape A4
          format = PdfPageFormat.a4.landscape;
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
                width: format.availableWidth,
                height: format.availableHeight,
              ),
            );
          },
        ),
      );
    }

    final output = await getTemporaryDirectory();
    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s\.-]'), '');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${output.path}/${sanitizedTitle}_$ts.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
