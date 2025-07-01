import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // REMOVE this import
import '../models/gatepass.dart';
import '../models/warehouse.dart';
import 'dart:convert';

class PrintService {
  Future<Uint8List> generateGatepassPDF(Gatepass gatepass, Warehouse warehouse) async {
    final pdf = pw.Document();

    // Generate QR code data as a string
    final qrData = jsonEncode({
      'serialNumber': gatepass.serialNumber,
      'dateTime': gatepass.dateTime.toIso8601String(),
      'invoiceNumber': gatepass.invoiceNumber,
      'partyName': gatepass.partyName,
      'gstNumber': gatepass.gstNumber,
      'address': gatepass.address,
      'vehicleNumber': gatepass.vehicleNumber,
      'quantity': gatepass.quantity,
      'productGrade': gatepass.productGrade,
    });

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with company logo and title
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'WAREHOUSE GATEPASS',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        warehouse.name,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        warehouse.address,
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  // Use BarcodeWidget for QR code
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrData,
                    width: 100,
                    height: 100,
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Gatepass details
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Serial Number: ${gatepass.serialNumber}',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text('Date: ${gatepass.dateTime.toString()}'),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Invoice No: ${gatepass.invoiceNumber}'),
                            pw.Text('Created By: ${gatepass.createdBy}'),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        _buildTableRow('Party Name', gatepass.partyName),
                        _buildTableRow('GST Number', gatepass.gstNumber),
                        _buildTableRow('Address', gatepass.address),
                        _buildTableRow('Vehicle Number', gatepass.vehicleNumber),
                        _buildTableRow('Quantity (MT)', gatepass.quantity.toString()),
                        _buildTableRow('Product Grade', gatepass.productGrade),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // Footer
              pw.Container(
                width: double.infinity,
                alignment: pw.Alignment.center,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'This is a computer-generated copy, No Signature is required',
                      style: pw.TextStyle(
                        fontStyle: pw.FontStyle.italic,
                        fontSize: 12,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Developed by Karan Infosys',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#808080'),
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text(value),
        ),
      ],
    );
  }

  Future<void> printGatepass(Gatepass gatepass, Warehouse warehouse) async {
    try {
      final pdfBytes = await generateGatepassPDF(gatepass, warehouse);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Gatepass_${gatepass.serialNumber}.pdf',
      );
    } catch (e) {
      print('Error printing gatepass: $e');
      rethrow;
    }
  }
} 