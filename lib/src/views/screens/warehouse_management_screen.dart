import 'package:flutter/material.dart';
import '../../models/warehouse.dart';
import '../../services/database_service.dart';

class WarehouseManagementScreen extends StatefulWidget {
  const WarehouseManagementScreen({super.key});

  @override
  State<WarehouseManagementScreen> createState() => _WarehouseManagementScreenState();
}

class _WarehouseManagementScreenState extends State<WarehouseManagementScreen> {
  final _dbService = DatabaseService();
  List<Warehouse> _warehouses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    setState(() => _isLoading = true);
    try {
      final warehouses = await _dbService.getAllWarehouses();
      setState(() => _warehouses = warehouses);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading warehouses: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showWarehouseDialog({Warehouse? warehouse}) async {
    final nameController = TextEditingController(text: warehouse?.name ?? '');
    final addressController = TextEditingController(text: warehouse?.address ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = warehouse != null;

    final result = await showDialog<Warehouse>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Warehouse' : 'Add Warehouse'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Warehouse Name/Number'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter warehouse name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter address' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newWarehouse = Warehouse(
                id: warehouse?.id,
                name: nameController.text,
                address: addressController.text,
                isActive: true,
              );
              try {
                if (isEdit) {
                  await _dbService.deleteWarehouse(warehouse.id!);
                }
                await _dbService.insertWarehouse(newWarehouse);
                Navigator.pop(context, newWarehouse);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving warehouse: $e')),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
    if (result != null) {
      _loadWarehouses();
    }
  }

  Future<void> _deleteWarehouse(Warehouse warehouse) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Warehouse'),
        content: Text('Are you sure you want to delete "${warehouse.name}"?'),
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
        await _dbService.deleteWarehouse(warehouse.id!);
        _loadWarehouses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Warehouse deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting warehouse: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Warehouses'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _warehouses.isEmpty
              ? const Center(child: Text('No warehouses found.'))
              : ListView.builder(
                  itemCount: _warehouses.length,
                  itemBuilder: (context, index) {
                    final warehouse = _warehouses[index];
                    return ListTile(
                      title: Text(warehouse.name),
                      subtitle: Text(warehouse.address),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showWarehouseDialog(warehouse: warehouse),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteWarehouse(warehouse),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWarehouseDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Add Warehouse',
      ),
    );
  }
} 