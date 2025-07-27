import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/party.dart';
import 'database_service.dart';

class ImportService {
  final DatabaseService _dbService = DatabaseService();

  Future<ImportResult> importFile(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    
    if (extension == 'csv') {
      return _importCsv(file);
    } else if (extension == 'xlsx' || extension == 'xls') {
      return _importExcel(file);
    } else {
      throw Exception('Unsupported file format. Please use CSV or Excel files.');
    }
  }

  Future<ImportResult> _importCsv(File file) async {
    final contents = await file.readAsString();
    final rows = const CsvToListConverter().convert(contents);
    
    if (rows.isEmpty) {
      throw Exception('File is empty');
    }

    final headers = List<String>.from(rows[0]);
    _validateHeaders(headers);

    final parties = <String, Party>{};

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final partyName = row[headers.indexOf('Party Name')].toString().trim();

      if (partyName.isNotEmpty) {
        parties[partyName] = Party(name: partyName);
      }
    }

    for (final party in parties.values) {
      await _dbService.insertParty(party);
    }

    return ImportResult(
      partyCount: parties.length,
      addressCount: 0, // No addresses in new structure
    );
  }

  Future<ImportResult> _importExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.keys.first;
    final rows = excel.tables[sheet]!.rows;

    if (rows.isEmpty) {
      throw Exception('File is empty');
    }

    final headers = rows[0].map((cell) => cell?.value.toString() ?? '').toList();
    _validateHeaders(headers);

    final parties = <String, Party>{};

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final partyName = row[headers.indexOf('Party Name')]?.value.toString() ?? '';

      if (partyName.isNotEmpty) {
        parties[partyName] = Party(name: partyName);
      }
    }

    for (final party in parties.values) {
      await _dbService.insertParty(party);
    }

    return ImportResult(
      partyCount: parties.length,
      addressCount: 0, // No addresses in new structure
    );
  }

  void _validateHeaders(List<String> headers) {
    final requiredHeaders = ['Party Name'];
    final missingHeaders = requiredHeaders
        .where((header) => !headers.contains(header))
        .toList();

    if (missingHeaders.isNotEmpty) {
      throw Exception(
        'Missing required columns: ${missingHeaders.join(', ')}',
      );
    }
  }
}

class ImportResult {

  ImportResult({
    required this.partyCount,
    required this.addressCount,
  });
  final int partyCount;
  final int addressCount;
} 