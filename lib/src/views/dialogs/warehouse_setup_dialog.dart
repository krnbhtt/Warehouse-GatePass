import 'package:flutter/material.dart';
import '../../models/warehouse.dart';
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
  bool _isLoading = false;

  Future<void> _saveWarehouse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final warehouse = Warehouse(
        name: _nameController.text,
        address: _addressController.text,
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