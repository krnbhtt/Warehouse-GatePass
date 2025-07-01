import 'package:flutter/material.dart';
import '../../widgets/branding_widgets.dart';
import '../../models/user.dart';
import 'gatepass_form_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  
  const HomeScreen({super.key, required this.user});
  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const GatepassFormScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Logo at the top
          BrandingWidgets.getLogo(),
          
          // Main content
          Expanded(
            child: _screens[_selectedIndex],
          ),
          
          // Footer at the bottom
          BrandingWidgets.getFooter(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'New Gatepass',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
} 