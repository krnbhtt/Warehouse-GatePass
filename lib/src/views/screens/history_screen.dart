import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/gatepass.dart';
import '../../models/party.dart';
import '../../models/warehouse.dart';
import '../../models/company.dart';
import '../../services/database_service.dart';
import '../../services/print_service.dart';
import '../../services/export_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dbService = DatabaseService();
  final _printService = PrintService();
  final _exportService = ExportService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  DateTime? _startDate;
  DateTime? _endDate;
  Party? _selectedParty;
  Warehouse? _selectedWarehouse;
  Company? _selectedCompany;
  List<Party> _parties = [];
  List<Warehouse> _warehouses = [];
  List<Company> _companies = [];
  List<Gatepass> _gatepasses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final parties = await _dbService.getAllParties();
      final warehouses = await _dbService.getAllWarehouses();
      final companies = await _dbService.getAllCompanies();
      setState(() {
        _parties = parties;
        _warehouses = warehouses;
        _companies = companies;
        if (companies.isNotEmpty) {
          _selectedCompany = companies.first;
        }
        if (warehouses.isNotEmpty) {
          _selectedWarehouse = warehouses.first;
        }
      });
      await _loadGatepasses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGatepasses() async {
    if (_startDate == null || _endDate == null) {
      // Set default date range to last 30 days if not selected
      final now = DateTime.now();
      _startDate = now.subtract(const Duration(days: 30));
      _endDate = now;
    }

    setState(() => _isLoading = true);
    try {
      final gatepasses = await _dbService.getGatepasses(
        startDate: _startDate,
        endDate: _endDate,
        partyName: _selectedParty?.name,
        warehouseId: _selectedWarehouse?.id,
        companyId: _selectedCompany?.id,
      );
      setState(() => _gatepasses = gatepasses);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading gatepasses: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadGatepasses();
    }
  }

  Future<void> _exportToExcel([List<Gatepass>? gatepassesToExport]) async {
    try {
      setState(() => _isLoading = true);
      final gatepassesToUse = gatepassesToExport ?? _gatepasses;
      final file = await _exportService.exportToExcel(gatepassesToUse, _warehouses, _companies);
      
      // Get the file bytes
      final bytes = await file.readAsBytes();
      
      // Save file using path_provider
      final directory = await getApplicationDocumentsDirectory();
      final savedFile = File('${directory.path}/Gatepass_Export_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await savedFile.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel file saved to: ${savedFile.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting to Excel: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reprintGatepass(Gatepass gatepass) async {
    try {
      final warehouse = _warehouses.firstWhere(
        (w) => w.id == gatepass.warehouseId,
        orElse: () => Warehouse(name: 'Unknown', address: 'Unknown'),
      );
      final company = _companies.firstWhere(
        (c) => c.id == gatepass.companyId,
        orElse: () => Company(name: 'Unknown Company'),
      );
      await _printService.printGatepass(gatepass, warehouse, company);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gatepass printed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing gatepass: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteGatepass(Gatepass gatepass) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Gatepass'),
        content: Text('Are you sure you want to delete this gatepass?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _dbService.deleteGatepass(gatepass.id);
        await _loadGatepasses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gatepass deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting gatepass: $e')),
          );
        }
      }
    }
  }

  Future<void> _cleanupOldData() async {
    // Calculate date 7 days ago (exclude today)
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    // Set to start of day to ensure we don't delete today's data
    final cutoffDate = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);
    
    // Get all gatepasses older than 7 days (before the cutoff date)
    final oldGatepasses = await _dbService.getGatepasses(
      endDate: cutoffDate,
    );
    
    if (oldGatepasses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data older than 7 days found')),
        );
      }
      return;
    }

    // Ask user if they want to download the data first
    final downloadFirst = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Data First?'),
        content: Text(
          'Found ${oldGatepasses.length} gatepasses older than 7 days (before ${cutoffDate.day}/${cutoffDate.month}/${cutoffDate.year}). '
          'Would you like to download this data before deleting it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Delete Only'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download & Delete'),
          ),
        ],
      ),
    );

    if (downloadFirst == null) return;

    try {
      setState(() => _isLoading = true);
      
      if (downloadFirst) {
        // Download the data first
        await _exportToExcel(oldGatepasses);
      }

      // Confirm deletion
      final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete ${oldGatepasses.length} gatepasses older than 7 days (before ${cutoffDate.day}/${cutoffDate.month}/${cutoffDate.year})? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmDelete == true) {
        // Delete old gatepasses
        for (final gatepass in oldGatepasses) {
          await _dbService.deleteGatepass(gatepass.id);
        }
        
        // Reload current data
        await _loadGatepasses();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully deleted ${oldGatepasses.length} old gatepasses (older than 7 days)'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during cleanup: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getCompanyName(int companyId) {
    try {
      return _companies.firstWhere((c) => c.id == companyId).name;
    } catch (e) {
      return 'Unknown Company';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Download button at the top right
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              onPressed: _cleanupOldData,
              tooltip: 'Cleanup Old Data (7 days)',
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _exportToExcel,
              tooltip: 'Export to Excel',
            ),
          ],
        ),
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _startDate != null && _endDate != null
                              ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                              : 'Select Date Range',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<Company>(
                        value: _selectedCompany,
                        decoration: const InputDecoration(
                          labelText: 'Company',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        items: _companies.map((company) {
                          return DropdownMenuItem(
                            value: company,
                            child: Text(company.name),
                          );
                        }).toList(),
                        onChanged: (Company? company) {
                          setState(() => _selectedCompany = company);
                          _loadGatepasses();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Warehouse>(
                        value: _selectedWarehouse,
                        decoration: const InputDecoration(
                          labelText: 'Warehouse',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        items: _warehouses.map((warehouse) {
                          return DropdownMenuItem(
                            value: warehouse,
                            child: Text(warehouse.name),
                          );
                        }).toList(),
                        onChanged: (Warehouse? warehouse) {
                          setState(() => _selectedWarehouse = warehouse);
                          _loadGatepasses();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<Party>(
                        value: _selectedParty,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Party',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        items: [
                          const DropdownMenuItem<Party>(
                            value: null,
                            child: Text('All Parties'),
                          ),
                          ..._parties.map((party) {
                            return DropdownMenuItem(
                              value: party,
                              child: Text(party.name),
                            );
                          }),
                        ],
                        onChanged: (Party? party) {
                          setState(() => _selectedParty = party);
                          _loadGatepasses();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _gatepasses.isEmpty
                  ? const Center(child: Text('No gatepasses found for the selected criteria'))
                  : ListView.builder(
                      itemCount: _gatepasses.length,
                      itemBuilder: (context, index) {
                        final gatepass = _gatepasses[index];
                        final warehouse = _warehouses.firstWhere(
                          (w) => w.id == gatepass.warehouseId,
                          orElse: () => Warehouse(name: 'Unknown', address: 'Unknown'),
                        );
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(gatepass.partyName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Company: ${_getCompanyName(gatepass.companyId)}'),
                                Text('Warehouse: ${warehouse.name}'),
                                Text('Serial: ${gatepass.serialNumber}'),
                                Text(
                                  'Date: ${_dateFormat.format(gatepass.dateTime)}',
                                ),
                                Text('Vehicle: ${gatepass.vehicleNumber}'),
                                Text('Quantity: ${gatepass.quantity} ${gatepass.quantityUnit}'),
                                Text('Grade: ${gatepass.productGrade}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.print),
                                  onPressed: () => _reprintGatepass(gatepass),
                                  tooltip: 'Reprint Gatepass',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _confirmDeleteGatepass(gatepass),
                                  tooltip: 'Delete Gatepass',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
} 