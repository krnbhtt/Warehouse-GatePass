import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/session_service.dart';
import '../../models/user.dart';
import '../../models/warehouse.dart';
import '../../models/company.dart';
import '../dialogs/warehouse_setup_dialog.dart';
import '../dialogs/user_setup_dialog.dart';
import 'home_screen.dart';
import 'master_upload_screen.dart';
import '../../widgets/branding_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dbService = DatabaseService();
  final _sessionService = SessionService();
  bool _isLoading = false;
  bool _isFirstTime = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      await _checkFirstTime();
      await _checkSession();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing app: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkSession() async {
    final isValid = await _sessionService.isSessionValid();
    if (isValid && mounted) {
      // Get the last logged in user from the database
      final users = await _dbService.getUsers();
      if (users.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: users.first),
          ),
        );
      }
    }
  }

  Future<void> _checkFirstTime() async {
    try {
      final users = await _dbService.getUsers();
      final companies = await _dbService.getAllCompanies();
      final warehouses = await _dbService.getAllWarehouses();
      final parties = await _dbService.getAllParties();
      
      setState(() {
        // Only show first time setup if there are no users, companies, warehouses, or parties
        _isFirstTime = users.isEmpty || companies.isEmpty || warehouses.isEmpty || parties.isEmpty;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking initialization: $e')),
        );
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await _dbService.authenticateUser(
        _usernameController.text,
        _passwordController.text,
      );

      if (user != null) {
        await _sessionService.updateLastActivity();
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: user,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid username or password')),
          );
        }
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

  Future<void> _showInitialSetup() async {
    // Step 1: Add Company (if needed)
    final companies = await _dbService.getAllCompanies();
    Company? selectedCompany;
    
    if (companies.isEmpty) {
      // Create a default company
      final defaultCompany = Company(name: 'Default Company', address: 'Default Address');
      await _dbService.insertCompany(defaultCompany);
      selectedCompany = defaultCompany;
    } else {
      selectedCompany = companies.first;
    }

    // Step 2: Add Warehouse
    final warehouse = await showDialog<Warehouse>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WarehouseSetupDialog(),
    );

    if (warehouse == null) return;

    // Step 3: Add Admin User
    final admin = await showDialog<User>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UserSetupDialog(
        isAdmin: true,
      ),
    );

    if (admin == null) return;

    // Step 4: Add Party Master
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MasterUploadScreen(),
        ),
      );
      
      // After party upload, refresh the screen to show login form
      if (mounted) {
        setState(() {
          _isFirstTime = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Logo at the top
          BrandingWidgets.getLogo(),
          
          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _initializeApp,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _isFirstTime
                        ? Center(
                            child: ElevatedButton(
                              onPressed: _showInitialSetup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Initialize Application'),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Welcome to Karan Infosys',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Gate Pass Management System',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person),
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
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.lock),
                                    ),
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : const Text('Login'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
          ),
          
          // Footer at the bottom
          BrandingWidgets.getFooter(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 