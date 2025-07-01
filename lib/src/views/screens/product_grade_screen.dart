import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../widgets/brand_header.dart';

class ProductGradeScreen extends StatefulWidget {
  const ProductGradeScreen({super.key});

  @override
  State<ProductGradeScreen> createState() => _ProductGradeScreenState();
}

class _ProductGradeScreenState extends State<ProductGradeScreen> {
  final _formKey = GlobalKey<FormState>();
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
      setState(() {
        _grades = grades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading grades: $e')),
        );
      }
    }
  }

  Future<void> _addGrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _dbService.addProductGrade(_gradeController.text);
      _gradeController.clear();
      await _loadGrades();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grade added successfully')),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting grade: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
                const BrandHeader(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _gradeController,
                            decoration: const InputDecoration(
                              labelText: 'New Grade',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a grade';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _addGrade,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _grades.length,
                    itemBuilder: (context, index) {
                      final grade = _grades[index];
                      return ListTile(
                        title: Text(grade),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteGrade(grade),
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