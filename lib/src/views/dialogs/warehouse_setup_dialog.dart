import 'package:flutter/material.dart';
import '../../models/warehouse.dart';
import '../../models/company.dart';
import '../../services/database_service.dart';

class WarehouseSetupDialog extends StatefulWidget {
  const WarehouseSetupDialog({super.key});

  @override
  State<WarehouseSetupDialog> createState() => _WarehouseSetupDialogState();
}

class _WarehouseSetupDialogState extends State<WarehouseSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _dbService = DatabaseService();
  List<Company> _companies = [];
  Company? _selectedCompany;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await _dbService.getAllCompanies();
      setState(() {
        _companies = companies;
        if (companies.isNotEmpty) {
          _selectedCompany = companies.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading companies: $e')),
        );
      }
    }
  }

  Future<void> _saveWarehouse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final warehouse = Warehouse(
        name: _nameController.text,
        address: _addressController.text,
        companyId: _selectedCompany?.id,
      );

      await _dbService.insertWarehouse(warehouse);
      if (mounted) {
        Navigator.pop(context, warehouse);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Setup Warehouse'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Company>(
              value: _selectedCompany,
              decoration: const InputDecoration(
                labelText: 'Company',
              ),
              items: _companies.map((company) {
                return DropdownMenuItem(
                  value: company,
                  child: Text(company.name),
                );
              }).toList(),
              onChanged: (Company? company) {
                setState(() => _selectedCompany = company);
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a company';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Warehouse Name/Number',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter warehouse name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveWarehouse,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
} 