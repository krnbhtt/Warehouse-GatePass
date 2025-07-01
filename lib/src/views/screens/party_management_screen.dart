import 'package:flutter/material.dart';
import '../../models/party.dart';
import '../../services/database_service.dart';

class PartyManagementScreen extends StatefulWidget {
  const PartyManagementScreen({super.key});

  @override
  State<PartyManagementScreen> createState() => _PartyManagementScreenState();
}

class _PartyManagementScreenState extends State<PartyManagementScreen> {
  final _dbService = DatabaseService();
  List<Party> _parties = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  Future<void> _loadParties() async {
    setState(() => _isLoading = true);
    try {
      final parties = await _dbService.getAllParties();
      setState(() => _parties = parties);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading parties: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showPartyDialog({Party? party}) async {
    final nameController = TextEditingController(text: party?.name ?? '');
    final gstController = TextEditingController(text: party?.gstNumber ?? '');
    final addressesController = TextEditingController(text: party != null ? party.addresses.join('\n') : '');
    final formKey = GlobalKey<FormState>();
    final isEdit = party != null;

    final result = await showDialog<Party>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Party' : 'Add Party'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Party Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter party name' : null,
                  readOnly: isEdit, // Don't allow editing name
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: gstController,
                  decoration: const InputDecoration(labelText: 'GST Number'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter GST number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressesController,
                  decoration: const InputDecoration(
                    labelText: 'Addresses',
                    hintText: 'One address per line',
                  ),
                  minLines: 2,
                  maxLines: 5,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter at least one address' : null,
                ),
              ],
            ),
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
              final addresses = addressesController.text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final newParty = Party(
                name: nameController.text.trim(),
                gstNumber: gstController.text.trim(),
                addresses: addresses,
              );
              try {
                if (isEdit) {
                  await _dbService.insertParty(newParty); // Overwrite
                } else {
                  await _dbService.insertParty(newParty);
                }
                Navigator.pop(context, newParty);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving party: $e')),
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
      await _loadParties();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Party updated successfully' : 'Party added successfully')),
        );
      }
    }
  }

  Future<void> _deleteParty(Party party) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Party'),
        content: Text('Are you sure you want to delete "${party.name}"?'),
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
        // There is no deleteParty in DatabaseService, so we need to add it if not present
        await _dbService.deleteParty(party.name);
        await _loadParties();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Party deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting party: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Parties'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parties.isEmpty
              ? const Center(child: Text('No parties found.'))
              : ListView.builder(
                  itemCount: _parties.length,
                  itemBuilder: (context, index) {
                    final party = _parties[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(party.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GST: ${party.gstNumber}'),
                            const SizedBox(height: 4),
                            Text('Addresses:'),
                            ...party.addresses.map((address) => Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text('• $address'),
                            )),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showPartyDialog(party: party),
                              tooltip: 'Edit Party',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteParty(party),
                              tooltip: 'Delete Party',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPartyDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Add Party',
      ),
    );
  }
} 