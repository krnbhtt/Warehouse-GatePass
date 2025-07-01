import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';

class UserSetupDialog extends StatefulWidget {

  const UserSetupDialog({
    super.key,
    required this.warehouseId,
    this.isAdmin = false,
  });
  final int warehouseId;
  final bool isAdmin;

  @override
  State<UserSetupDialog> createState() => _UserSetupDialogState();
}

class _UserSetupDialogState extends State<UserSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dbService = DatabaseService();
  bool _isLoading = false;

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = User(
        username: _usernameController.text,
        password: _passwordController.text,
        role: widget.isAdmin ? 'admin' : 'user',
        warehouseId: widget.warehouseId,
      );

      await _dbService.insertUser(user);
      if (mounted) {
        Navigator.pop(context, user);
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
      title: Text(widget.isAdmin ? 'Setup Admin User' : 'Add New User'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
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
          onPressed: _isLoading ? null : _saveUser,
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