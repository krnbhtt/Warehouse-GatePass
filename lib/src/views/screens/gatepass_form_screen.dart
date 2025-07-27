import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/gatepass.dart';
import '../../models/party.dart';
import '../../models/warehouse.dart';
import '../../models/company.dart';
import '../../services/database_service.dart';
import '../../services/print_service.dart';

/// A screen that displays a form for creating new gatepass entries.
/// 
/// This screen allows users to input details such as company, warehouse,
/// party name, vehicle number, quantity with unit, and product grade
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

  final _vehicleController = TextEditingController();
  final _quantityController = TextEditingController();
  final _approvedByController = TextEditingController();
  final _approverNameController = TextEditingController();

  Company? _selectedCompany;
  Warehouse? _selectedWarehouse;
  Party? _selectedParty;
  String? _selectedGrade;
  String _selectedQuantityUnit = 'MT';
  List<Company> _companies = [];
  List<Warehouse> _warehouses = [];
  List<Party> _parties = [];
  List<String> _grades = [];
  List<String> _vehicleSuggestions = [];
  bool _isLoading = false;
  bool _showVehicleSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _quantityController.dispose();
    _approvedByController.dispose();
    _approverNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final companies = await _dbService.getAllCompanies();
      final parties = await _dbService.getAllParties();
      final grades = await _dbService.getProductGrades();
      if (mounted) {
        setState(() {
          _companies = companies;
          _parties = parties;
          _grades = grades;
          if (companies.isNotEmpty) {
            _selectedCompany = companies.first;
            _loadWarehousesForCompany(companies.first.id!);
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

  Future<void> _loadWarehousesForCompany(int companyId) async {
    try {
      final warehouses = await _dbService.getWarehousesByCompany(companyId);
      if (mounted) {
        setState(() {
          _warehouses = warehouses;
          _selectedWarehouse = warehouses.isNotEmpty ? warehouses.first : null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading warehouses: $e')),
        );
      }
    }
  }

  Future<void> _submitForm(bool shouldPrint) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final serialNumber = await _dbService.generateSerialNumber(_selectedWarehouse!.id!);
      
      final gatepass = Gatepass(
        serialNumber: serialNumber,
        dateTime: DateTime.now(),
        companyId: _selectedCompany!.id!,
        warehouseId: _selectedWarehouse!.id!,
        invoiceNumber: '', // Not needed in new structure
        partyName: _selectedParty!.name,
        vehicleNumber: _vehicleController.text.toUpperCase(),
        quantity: double.parse(_quantityController.text),
        quantityUnit: _selectedQuantityUnit,
        productGrade: _selectedGrade!,
        createdBy: 'User', // Default value
        approvedBy: _approvedByController.text.trim().isEmpty ? null : _approvedByController.text.trim(),
        approverName: _approverNameController.text.trim().isEmpty ? null : _approverNameController.text.trim(),
      );

      await _dbService.insertGatepass(gatepass);

      if (shouldPrint) {
        try {
          await _printService.printGatepass(gatepass, _selectedWarehouse!, _selectedCompany!);
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
        
        // Clear the form instead of navigating back
        _clearForm();
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

  void _clearForm() {
    _vehicleController.clear();
    _quantityController.clear();
    _approvedByController.clear();
    _approverNameController.clear();
    _selectedParty = null;
    _selectedGrade = _grades.isNotEmpty ? _grades.first : null;
    _selectedQuantityUnit = 'MT';
    
    // Reset form validation
    _formKey.currentState?.reset();
  }

  Future<void> _loadVehicleSuggestions(String prefix) async {
    if (prefix.length < 2) {
      setState(() {
        _vehicleSuggestions = [];
        _showVehicleSuggestions = false;
      });
      return;
    }

    try {
      final suggestions = await _dbService.getVehicleNumbersByPrefix(prefix.toUpperCase());
      if (mounted) {
        setState(() {
          _vehicleSuggestions = suggestions;
          _showVehicleSuggestions = suggestions.isNotEmpty;
        });
      }
    } catch (e) {
      // Silently handle errors for autocomplete
      if (mounted) {
        setState(() {
          _vehicleSuggestions = [];
          _showVehicleSuggestions = false;
        });
      }
    }
  }

  void _selectVehicleSuggestion(String vehicleNumber) {
    _vehicleController.text = vehicleNumber;
    setState(() {
      _showVehicleSuggestions = false;
    });
    // Move focus to next field
    FocusScope.of(context).nextFocus();
  }

  void _hideVehicleSuggestions() {
    setState(() {
      _showVehicleSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : GestureDetector(
            onTap: _hideVehicleSuggestions,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Company Selection
                  DropdownButtonFormField<Company>(
                    value: _selectedCompany,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                    ),
                    items: _companies.map((company) {
                      return DropdownMenuItem(
                        value: company,
                        child: Text(company.name),
                      );
                    }).toList(),
                    onChanged: (Company? company) {
                      setState(() {
                        _selectedCompany = company;
                        _selectedWarehouse = null;
                      });
                      if (company != null) {
                        _loadWarehousesForCompany(company.id!);
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a company';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Warehouse Selection
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

                  // Party Name Selection
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

                  // Vehicle Number
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _vehicleController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Number',
                          hintText: 'Format: GJ01AB1234, GJ01A.1234, or 25BH1234AB',
                          suffixIcon: Icon(Icons.search),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9.]')),
                          LengthLimitingTextInputFormatter(12),
                        ],
                        onChanged: (value) {
                          _loadVehicleSuggestions(value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter vehicle number';
                          }
                          
                          // Check for Bharat plate format: YY BH #### XX (e.g., 25BH1234AB)
                          if (RegExp(r'^\d{2}BH\d{4}[A-Z]{2}$').hasMatch(value)) {
                            return null;
                          }
                          
                          // Check for standard format with dot: GJ01A.1234
                          if (RegExp(r'^[A-Z]{2}\d{2}[A-Z]\.\d{4}$').hasMatch(value)) {
                            return null;
                          }
                          
                          // Check for standard format: GJ01AB1234
                          if (RegExp(r'^[A-Z]{2}\d{2}[A-Z]{2}\d{4}$').hasMatch(value)) {
                            return null;
                          }
                          
                          return 'Please enter a valid vehicle number format:\n• Standard: GJ01AB1234\n• With dot: GJ01A.1234\n• Bharat: 25BH1234AB';
                        },
                      ),
                      if (_showVehicleSuggestions && _vehicleSuggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _vehicleSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _vehicleSuggestions[index];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  suggestion,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                leading: const Icon(Icons.directions_car, size: 20),
                                onTap: () => _selectVehicleSuggestion(suggestion),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Product Grade
                  DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'Grade',
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
                  const SizedBox(height: 16),

                  // Quantity with Unit Selection
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
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
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedQuantityUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'MT', child: Text('MT')),
                            DropdownMenuItem(value: 'Bags', child: Text('Bags')),
                          ],
                          onChanged: (String? unit) {
                            setState(() => _selectedQuantityUnit = unit!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
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
          ),
        );
  }
} 