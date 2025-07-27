import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/gatepass.dart';
import '../models/warehouse.dart';
import '../models/company.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';

class PrintService {
  Future<Uint8List> generateGatepassPDF(Gatepass gatepass, Warehouse warehouse, Company company) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            children: [
              // First Gatepass (Top Half)
              _buildGatepassSection(gatepass, warehouse, company, 'ORIGINAL'),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              // Second Gatepass (Bottom Half) - Duplicate
              _buildGatepassSection(gatepass, warehouse, company, 'DUPLICATE'),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildGatepassSection(Gatepass gatepass, Warehouse warehouse, Company company, String copyType) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header with company name and copy type
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    company.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'WAREHOUSE GATEPASS',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    warehouse.name,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (warehouse.address.isNotEmpty)
                    pw.Text(
                      warehouse.address,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  copyType,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Gatepass details
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
                  pw.Text('Date: ${_formatDateTime(gatepass.dateTime)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Details table
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              _buildTableRow('Party Name', gatepass.partyName),
              _buildTableRow('Vehicle Number', gatepass.vehicleNumber),
              _buildTableRow('Grade', gatepass.productGrade),
              _buildTableRow('Quantity', '${gatepass.quantity} ${gatepass.quantityUnit}'),
            ],
          ),
          pw.SizedBox(height: 16),

          // Approval section - always show, even if empty
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Approved By: ${gatepass.approvedBy ?? '________________'}'),
              pw.Text('Sign: ${gatepass.approverName ?? '________________'}'),
            ],
          ),
          pw.SizedBox(height: 16),

          // Footer
          pw.Container(
            width: double.infinity,
            alignment: pw.Alignment.center,
            child: pw.Column(
              children: [
                pw.Text(
                  'This is a computer-generated copy, No Signature is required',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 10,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Developed by Karan Infosys',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor.fromHex('#808080'),
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  Future<void> printGatepass(Gatepass gatepass, Warehouse warehouse, Company company) async {
    try {
      final pdfBytes = await generateGatepassPDF(gatepass, warehouse, company);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Gatepass_${gatepass.serialNumber}.pdf',
      );
    } catch (e) {
      print('Error printing gatepass: $e');
      rethrow;
    }
  }

  /// Print to a selected network printer
  Future<void> printToNetworkPrinter(Gatepass gatepass, Warehouse warehouse, Company company, Printer printer) async {
    try {
      final pdfBytes = await generateGatepassPDF(gatepass, warehouse, company);
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) async => pdfBytes,
        name: 'Gatepass_${gatepass.serialNumber}.pdf',
      );
    } catch (e) {
      print('Error printing to network printer: $e');
      rethrow;
    }
  }

  /// Discover WiFi printers on the local network (example: scan subnet 192.168.1.*)
  Future<List<String>> discoverWiFiPrinters({String subnet = '192.168.1', int port = 9100}) async {
    List<String> foundPrinters = [];
    final stream = NetworkAnalyzer.discover2(subnet, port, timeout: Duration(milliseconds: 500));
    await for (final NetworkAddress addr in stream) {
      if (addr.exists) {
        foundPrinters.add(addr.ip);
      }
    }
    return foundPrinters;
  }

  /// Print a simple ESC/POS ticket to a WiFi printer by IP address
  Future<void> printToWiFiPrinter(String ip, List<int> ticketBytes, {int port = 9100}) async {
    final printer = PrinterNetworkManager(ip, port: port);
    final PosPrintResult res = await printer.connect();
    if (res == PosPrintResult.success) {
      await printer.printTicket(ticketBytes);
      await printer.disconnect();
    } else {
      throw Exception('Could not connect to printer at $ip');
    }
  }
} 