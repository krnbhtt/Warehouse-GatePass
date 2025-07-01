import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final _dbService = DatabaseService();
  final _gradeController = TextEditingController();
  List<String> _grades = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      final grades = await _dbService.getProductGrades();
      setState(() => _grades = grades);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading grades: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addGrade() async {
    if (_gradeController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _dbService.addProductGrade(_gradeController.text);
      _gradeController.clear();
      await _loadGrades();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grade added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding grade')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding grade: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteGrade(String grade) async {
    setState(() => _isLoading = true);
    try {
      await _dbService.deleteProductGrade(grade);
      await _loadGrades();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grade deleted successfully')),
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting grade')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting grade: $e')),
        );
      }    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editGrade(String oldGrade) async {
    final controller = TextEditingController(text: oldGrade);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Grade'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Grade Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a grade';
              }
              if (_grades.contains(value) && value != oldGrade) {
                return 'Grade already exists';
              }
              return null;
            },
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
              final newGrade = controller.text.trim();
              try {
                await _dbService.deleteProductGrade(oldGrade);
                await _dbService.addProductGrade(newGrade);
                Navigator.pop(context, newGrade);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating grade: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _loadGrades();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grade updated successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Grades'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _gradeController,
                          decoration: const InputDecoration(
                            labelText: 'New Grade',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _addGrade,
                        child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Grade'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _grades.length,
                          itemBuilder: (context, index) {
                            final grade = _grades[index];
                            return ListTile(
                              title: Text(grade),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: _isLoading ? null : () => _editGrade(grade),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: _isLoading ? null : () => _deleteGrade(grade),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 