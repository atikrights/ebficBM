import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:ebficbm/features/projects/models/project.dart';
import 'package:universal_html/html.dart' as html;

class ProjectExporter {
  static Future<void> exportToPdf(Project project, {BuildContext? context}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Certificate Header
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.blueGrey, width: 1.5),
                ),
                child: pw.Column(
                  children: [
                    pw.Text('OFFICIAL PROJECT CERTIFICATE',
                        style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, letterSpacing: 3, color: PdfColors.blueGrey900)),
                    pw.SizedBox(height: 4),
                    pw.Text('AUTHENTICATED BY EBFIC BUSINESS ECOSYSTEM',
                        style: pw.TextStyle(fontSize: 9, letterSpacing: 2, color: PdfColors.blueGrey400)),
                  ],
                ),
              ),
              pw.SizedBox(height: 50),

              pw.Center(
                  child: pw.Text(project.name.toUpperCase(),
                      style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
              pw.SizedBox(height: 8),
              pw.Center(
                  child: pw.Text('CORE PROJECT REGISTRATION ID: ${project.pid}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700, letterSpacing: 1))),
              pw.SizedBox(height: 40),

              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                decoration: pw.BoxDecoration(color: PdfColors.blueGrey50, borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _infoBlock('CATEGORY', project.category),
                        _infoBlock('STATUS', project.status.name.toUpperCase()),
                        _infoBlock('START DATE', project.startDate.toString().substring(0, 10)),
                      ],
                    ),
                    pw.SizedBox(height: 24),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _infoBlock('BUDGET ALLOCATION', '\$${project.totalBudget.toStringAsFixed(0)}'),
                        _infoBlock('PROJECT MANAGER', project.managerSignature.isEmpty ? 'AUTHORIZED PERSONNEL' : project.managerSignature),
                        _infoBlock('CONTACT', project.phoneNumber.isEmpty ? 'OFFICIAL REGISTRY' : project.phoneNumber),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blueGrey100), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('STRATEGIC INSPIRATION & VISION',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey600, letterSpacing: 1)),
                    pw.SizedBox(height: 12),
                    pw.Text(
                        project.inspirationText.isEmpty
                            ? 'Operating under standard strategic protocols for enterprise deployment.'
                            : project.inspirationText,
                        style: pw.TextStyle(fontSize: 11, lineSpacing: 5, fontStyle: pw.FontStyle.italic)),
                  ],
                ),
              ),

              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 100,
                        height: 100,
                        decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle, border: pw.Border.all(color: PdfColors.blueGrey200, width: 2)),
                        child: pw.Center(
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text('ebfic',
                                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                                pw.Text('Business',
                                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey600)),
                                pw.Text('Manager',
                                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey600)),
                                pw.Container(height: 0.5, width: 40, color: PdfColors.blueGrey200, margin: const pw.EdgeInsets.symmetric(vertical: 2)),
                                pw.Text('OFFICIAL SEAL', style: const pw.TextStyle(fontSize: 5, color: PdfColors.blueGrey300)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Corporate Authenticity',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey200, letterSpacing: 1)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(project.managerSignature.isEmpty ? 'EBFIC MANAGER' : project.managerSignature,
                          style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Container(width: 180, height: 1.2, color: PdfColors.blueGrey800),
                      pw.SizedBox(height: 6),
                      pw.Text('AUTHORIZED PROJECT SIGNATURE',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              pw.Divider(thickness: 0.5, color: PdfColors.blueGrey100),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by eBM System (Enterprise Business Manager)',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey300)),
                  pw.Text('© 2026 EBFIC GLOBAL ECOSYSTEM',
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey300)),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = '${project.name.replaceAll(' ', '_')}_Certificate.pdf';

    if (kIsWeb) {
      // Web: trigger browser file download
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..download = fileName
        ..style.display = 'none';
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile / Desktop: save to temp dir and open with system viewer
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await OpenFilex.open(file.path);
      } catch (e) {
        debugPrint('PDF export error: $e');
      }
    }
  }

  static pw.Widget _infoBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
