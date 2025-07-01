import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
// import '../../services/sync_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'login_screen.dart';
// import '../../services/database_service.dart';
import 'grades_screen.dart';
import 'master_upload_screen.dart';
// import '../../widgets/branding_widgets.dart';
import '../../services/session_service.dart';
import 'warehouse_management_screen.dart';
import 'party_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  bool _hasBluetoothPermission = false;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final bluetoothStatus = await Permission.bluetooth.status;
    final bluetoothScanStatus = await Permission.bluetoothScan.status;
    final locationStatus = await Permission.location.status;

    setState(() {
      _hasBluetoothPermission = bluetoothStatus.isGranted && bluetoothScanStatus.isGranted;
      _hasLocationPermission = locationStatus.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    final bluetoothStatus = await Permission.bluetooth.request();
    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    final locationStatus = await Permission.location.request();

    setState(() {
      _hasBluetoothPermission = bluetoothStatus.isGranted && bluetoothScanStatus.isGranted;
      _hasLocationPermission = locationStatus.isGranted;
    });

    if (_hasBluetoothPermission && _hasLocationPermission) {
      _startScan();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth and Location permissions are required for printer setup'),
          ),
        );
      }
    }
  }

  Future<void> _startScan() async {
    if (!_hasBluetoothPermission || !_hasLocationPermission) {
      await _requestPermissions();
      return;
    }

    // Only attempt to use flutter_blue_plus on Android and iOS
    if (Theme.of(context).platform != TargetPlatform.android && Theme.of(context).platform != TargetPlatform.iOS) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bluetooth scanning is only supported on Android and iOS.'),
              ),
            );
          }
          return;
    }

    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    try {
      // Check if Bluetooth is available and turned on
      if (await FlutterBluePlus.isAvailable == false) {
        throw Exception('Bluetooth is not available on this device');
      }

      if (await FlutterBluePlus.isOn == false) {
        throw Exception('Please turn on Bluetooth');
      }

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          _scanResults = results;
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToPrinter(ScanResult result) async {
    try {
      await result.device.connect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${result.device.name}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting: $e')),
        );
      }
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await SessionService().clearSession();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Us'),
                subtitle: const Text('Application & Company Information'),
                onTap: () => _showAboutDialog(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Printer Setup'),
                subtitle: Text(
                  !_hasBluetoothPermission || !_hasLocationPermission
                      ? 'Permissions required'
                      : 'Scan for nearby printers',
                ),
                onTap: _startScan,
              ),
              if (_isScanning)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_scanResults.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Available Printers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 200, // Fixed height for the printer list
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      return ListTile(
                        leading: const Icon(Icons.print),
                        title: Text(result.device.name.isNotEmpty
                            ? result.device.name
                            : 'Unknown Device'),
                        subtitle: Text(result.device.id.id),
                        trailing: ElevatedButton(
                          onPressed: () => _connectToPrinter(result),
                          child: const Text('Connect'),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Upload Party Master'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MasterUploadScreen()));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Manage Product Grades'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GradesScreen()));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.warehouse),
                title: const Text('Manage Warehouses'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WarehouseManagementScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Manage Parties'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PartyManagementScreen()));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: _handleLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Image.asset(
              'assets/images/Icon.png',
              height: 100,
              width: 100,
            ),
            const SizedBox(height: 16),
            const Text(
              'Karan Infosys',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Text(
              'Gate Pass Management System',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About the Application',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A comprehensive warehouse gate pass management solution designed to streamline logistics operations. '
                'This application provides secure, efficient, and user-friendly gate pass generation and management capabilities.',
              ),
              const SizedBox(height: 16),
              Text(
                'Version: ${packageInfo.version}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'About Karan Infosys',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Karan Infosys is a leading technology solutions provider specializing in custom software development, '
                'mobile applications, and enterprise solutions. We are committed to delivering innovative, '
                'reliable, and scalable software solutions that help businesses optimize their operations.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Our Services:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Custom Software Development'),
              const Text('• Mobile Application Development'),
              const Text('• Web Development'),
              const Text('• Enterprise Solutions'),
              const Text('• IT Consulting'),
              const SizedBox(height: 16),
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('+91 9898564714'),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('karan@karaninfosys.com'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '© 2025 Karan Infosys. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 