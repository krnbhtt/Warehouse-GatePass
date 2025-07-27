import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/gatepass.dart';
import '../models/warehouse.dart';
import '../models/company.dart';

class ExportService {
  Future<File> exportToExcel(List<Gatepass> gatepasses, List<Warehouse> warehouses, List<Company> companies) async {
    final excel = Excel.createExcel();
    final sheet = excel.sheets.values.first;

    // Add headers
    final headers = [
      'Serial Number',
      'Date & Time',
      'Company',
      'Warehouse',
      'Party Name',
      'Vehicle Number',
      'Quantity',
      'Unit',
      'Product Grade',
      'Created By',
      'Approved By',
      'Approver Name',
      'Printed',
      'Synced',
    ];

    // Add headers with styling
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
      );
    }

    // Add data
    for (var i = 0; i < gatepasses.length; i++) {
      final gatepass = gatepasses[i];
      final warehouse = warehouses.firstWhere(
        (w) => w.id == gatepass.warehouseId,
        orElse: () => Warehouse(name: 'Unknown', address: 'Unknown'),
      );
      final company = companies.firstWhere(
        (c) => c.id == gatepass.companyId,
        orElse: () => Company(name: 'Unknown Company'),
      );

      final row = i + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(gatepass.serialNumber);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(gatepass.dateTime.toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(company.name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(warehouse.name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(gatepass.partyName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(gatepass.vehicleNumber);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(gatepass.quantity.toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = TextCellValue(gatepass.quantityUnit);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = TextCellValue(gatepass.productGrade);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = TextCellValue(gatepass.createdBy);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value = TextCellValue(gatepass.approvedBy ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value = TextCellValue(gatepass.approverName ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row)).value = TextCellValue(gatepass.isPrinted ? 'Yes' : 'No');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row)).value = TextCellValue(gatepass.isSynced ? 'Yes' : 'No');
    }

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Gatepass_Export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(excel.encode()!);

    return file;
  }
} 