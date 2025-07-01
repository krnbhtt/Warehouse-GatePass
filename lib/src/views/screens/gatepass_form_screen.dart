import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/gatepass.dart';
import '../../models/party.dart';
import '../../models/warehouse.dart';
import '../../services/database_service.dart';
import '../../services/print_service.dart';
// import '../../widgets/branding_widgets.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';

/// A screen that displays a form for creating new gatepass entries.
/// 
/// This screen allows users to input details such as invoice number,
/// vehicle number, quantity, and select party and warehouse information
/// to generate a new gatepass.
class GatepassFormScreen extends StatefulWidget {
  const GatepassFormScreen({super.key});

  @override
  State<GatepassFormScreen> createState() => _GatepassFormScreenState();
}

class _GatepassFormScreenState extends State<GatepassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();
  final _printService = PrintService();

  final _invoiceController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _quantityController = TextEditingController();

  Party? _selectedParty;
  String? _selectedAddress;
  Warehouse? _selectedWarehouse;
  String? _selectedGrade;
  List<Party> _parties = [];
  List<Warehouse> _warehouses = [];
  List<String> _grades = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _vehicleController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final parties = await _dbService.getAllParties();
      final warehouses = await _dbService.getAllWarehouses();
      final grades = await _dbService.getProductGrades();
      if (mounted) {
        setState(() {
          _parties = parties;
          _warehouses = warehouses;
          _grades = grades;
          if (warehouses.isNotEmpty) {
            _selectedWarehouse = warehouses.first;
          }
          if (grades.isNotEmpty) {
            _selectedGrade = grades.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _submitForm(bool shouldPrint) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWarehouse == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a warehouse')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final serialNumber = await _dbService.generateSerialNumber(_selectedWarehouse!.id!);
      
      final gatepass = Gatepass(
        dateTime: DateTime.now(),
        serialNumber: serialNumber,
        warehouseId: _selectedWarehouse!.id!,
        invoiceNumber: _invoiceController.text,
        partyName: _selectedParty!.name,
        gstNumber: _selectedParty!.gstNumber,
        address: _selectedAddress!,
        vehicleNumber: _vehicleController.text,
        quantity: double.parse(_quantityController.text),
        productGrade: _selectedGrade!,
        createdBy: (await _dbService.getCurrentUser())?.username ?? 'Unknown User',
        isPrinted: shouldPrint,
      );

      await _dbService.insertGatepass(gatepass);

      if (shouldPrint) {
        final warehouse = _warehouses.firstWhere((w) => w.id == gatepass.warehouseId);
        try {
          await _printService.printGatepass(gatepass, warehouse);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error printing gatepass: $e')),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gatepass created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<Warehouse>(
                    value: _selectedWarehouse,
                    decoration: const InputDecoration(
                      labelText: 'Warehouse',
                    ),
                    items: _warehouses.map((warehouse) {
                      return DropdownMenuItem(
                        value: warehouse,
                        child: Text(warehouse.name),
                      );
                    }).toList(),
                    onChanged: (Warehouse? warehouse) {
                      setState(() {
                        _selectedWarehouse = warehouse;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a warehouse';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _invoiceController,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Number',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter invoice number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Party>(
                    value: _selectedParty,
                    decoration: const InputDecoration(
                      labelText: 'Party Name',
                    ),
                    items: _parties.map((party) {
                      return DropdownMenuItem(
                        value: party,
                        child: Text(party.name),
                      );
                    }).toList(),
                    onChanged: (Party? party) {
                      setState(() {
                        _selectedParty = party;
                        _selectedAddress = null;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a party';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedParty != null) ...[
                    TextFormField(
                      initialValue: _selectedParty!.gstNumber,
                      decoration: const InputDecoration(
                        labelText: 'GST Number',
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedAddress,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                      ),
                      items: _selectedParty!.addresses.map((address) {
                        return DropdownMenuItem(
                          value: address,
                          child: Text(address),
                        );
                      }).toList(),
                      onChanged: (String? address) {
                        setState(() => _selectedAddress = address);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select an address';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehicleController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Number',
                      hintText: 'Format: GJ01AB1234',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter vehicle number';
                      }
                      if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{2}[0-9]{4}$').hasMatch(value)) {
                        return 'Please enter a valid vehicle number (e.g., GJ01AB1234)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (MT)',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'Product Grade',
                      hintText: 'Select a grade',
                    ),
                    items: _grades.map((grade) {
                      return DropdownMenuItem(
                        value: grade,
                        child: Text(grade),
                      );
                    }).toList(),
                    onChanged: (String? grade) {
                      setState(() => _selectedGrade = grade);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a product grade';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _submitForm(false),
                          child: const Text('Save Only'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _submitForm(true),
                          child: const Text('Submit & Print'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }
} 