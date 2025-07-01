import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/gatepass.dart';
import '../../models/party.dart';
import '../../models/warehouse.dart';
import '../../services/database_service.dart';
import '../../services/print_service.dart';
import '../../services/export_service.dart';
// import '../../widgets/branding_widgets.dart';
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
  List<Party> _parties = [];
  List<Warehouse> _warehouses = [];
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
      setState(() {
        _parties = parties;
        _warehouses = warehouses;
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

  Future<void> _exportToExcel() async {
    try {
      setState(() => _isLoading = true);
      final file = await _exportService.exportToExcel(_gatepasses, _warehouses);
      
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
      await _printService.printGatepass(gatepass, warehouse);
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

  Future<void> _editGatepass(Gatepass gatepass) async {
    final _invoiceController = TextEditingController(text: gatepass.invoiceNumber);
    final _vehicleController = TextEditingController(text: gatepass.vehicleNumber);
    final _quantityController = TextEditingController(text: gatepass.quantity.toString());
    final _addressController = TextEditingController(text: gatepass.address);
    String selectedGrade = gatepass.productGrade;
    final grades = await _dbService.getProductGrades();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Gatepass'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _invoiceController,
                  decoration: const InputDecoration(labelText: 'Invoice Number'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter invoice number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(labelText: 'Vehicle Number'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter vehicle number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity (MT)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter quantity';
                    if (double.tryParse(value) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedGrade,
                  decoration: const InputDecoration(labelText: 'Product Grade'),
                  items: grades.map((grade) => DropdownMenuItem(
                    value: grade,
                    child: Text(grade),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) selectedGrade = value;
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Please select a product grade' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter address' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final updatedGatepass = gatepass.copyWith(
                  invoiceNumber: _invoiceController.text,
                  vehicleNumber: _vehicleController.text,
                  quantity: double.parse(_quantityController.text),
                  productGrade: selectedGrade,
                  address: _addressController.text,
                );
                await _dbService.updateGatepass(updatedGatepass);
                Navigator.pop(context, true);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating gatepass: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true) {
      await _loadGatepasses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gatepass updated successfully')),
        );
      }
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
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Party>(
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
                                Text('Warehouse: ${warehouse.name}'),
                                Text('Serial: ${gatepass.serialNumber}'),
                                Text('Invoice: ${gatepass.invoiceNumber}'),
                                Text(
                                  'Date: ${_dateFormat.format(gatepass.dateTime)}',
                                ),
                                Text('Vehicle: ${gatepass.vehicleNumber}'),
                                Text('Quantity: ${gatepass.quantity} MT'),
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
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editGatepass(gatepass),
                                  tooltip: 'Edit Gatepass',
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