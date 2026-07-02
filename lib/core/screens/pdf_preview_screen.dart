import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// A full-screen PDF preview with a system AppBar (back button) and
/// built-in print / share / download toolbar provided by [PdfPreview].
/// Push it via [PdfPreviewScreen.push] — it uses the standard Navigator
/// so go_router doesn't need a named route for this overlay screen.
class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.fileName,
    required this.loadBytes,
  });

  final String title;
  final String fileName;
  /// Returns the raw PDF bytes. Called by [PdfPreview] on first build and
  /// on any page-format change.
  final Future<Uint8List> Function() loadBytes;

  /// Pushes the preview screen on top of the current route and awaits dismiss.
  static Future<void> push(
    BuildContext context, {
    required String title,
    required String fileName,
    required Future<Uint8List> Function() loadBytes,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: title,
          fileName: fileName,
          loadBytes: loadBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        // PdfPreview passes the current page format; we ignore it since the
        // server already generates the PDF in the correct thermal/A4 size.
        build: (_) => loadBytes(),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: fileName,
      ),
    );
  }
}
