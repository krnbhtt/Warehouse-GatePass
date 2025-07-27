import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../models/party.dart';
import '../../services/database_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class MasterUploadScreen extends StatefulWidget {
  const MasterUploadScreen({super.key});

  @override
  State<MasterUploadScreen> createState() => _MasterUploadScreenState();
}

class _MasterUploadScreenState extends State<MasterUploadScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = false;
  final List<Party> _parties = [];
  FilePickerResult? _selectedFile;
  bool _showConfirmation = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result == null) return;

      setState(() {
        _selectedFile = result;
        _showConfirmation = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null) return;

    try {
      setState(() => _isLoading = true);
      final file = _selectedFile!.files.first;
      
      // Read file content
      String csvString;
      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('Could not read file contents');
        }
        csvString = utf8.decode(file.bytes!);
      } else {
        if (file.path == null) {
          throw Exception('Could not read file contents');
        }
        final fileContent = await File(file.path!).readAsString();
        csvString = fileContent;
      }

      // Process CSV content
      final lines = csvString.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      
      if (lines.length < 2) {
        throw Exception('CSV file must contain at least a header row and one data row');
      }

      _parties.clear();

      // Skip header row
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final row = _parseCsvLine(line);

        if (row.length < 1) {
          throw Exception('Row ${i + 1} is missing required columns. Found ${row.length} columns, expected 1.');
        }

        final partyName = row[0].trim();
        if (partyName.isNotEmpty) {
          final party = Party(name: partyName);
          _parties.add(party);
        }
      }

      // Save to database
      for (final party in _parties) {
        await _dbService.insertParty(party);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${_parties.length} parties'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to settings screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _showConfirmation = false;
        _selectedFile = null;
      });
    }
  }

  List<String> _parseCsvLine(String line) {
    // Remove outer quotes if present
    if (line.startsWith('"') && line.endsWith('"')) {
      line = line.substring(1, line.length - 1);
    }

    List<String> result = [];
    String current = '';
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      if (line[i] == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          // Handle escaped quotes
          current += '"';
          i++; // Skip the next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (line[i] == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += line[i];
      }
    }
    result.add(current.trim());

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Party Master'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _showConfirmation
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Selected file: ${_selectedFile!.files.first.name}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _processFile,
                                    icon: const Icon(Icons.check),
                                    label: const Text('Proceed'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _showConfirmation = false;
                                        _selectedFile = null;
                                      });
                                    },
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Cancel'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CSV File Format',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'The CSV file should have the following columns:\n'
                                        '1. Party Name\n\n'
                                        'Example:\n'
                                        'Tata Steel Ltd\n'
                                        'ABC Corporation\n'
                                        'XYZ Traders',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _pickFile,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Select CSV File'),
                              ),
                            ],
                          ),
                        ),
                ),
                if (_parties.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Imported Parties',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _parties.length,
                      itemBuilder: (context, index) {
                        final party = _parties[index];
                        return Card(
                          child: ListTile(
                            title: Text(party.name),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}