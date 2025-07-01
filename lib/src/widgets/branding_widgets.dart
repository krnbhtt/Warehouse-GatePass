import 'package:flutter/material.dart';

class BrandingWidgets {
  static Widget getLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Image.asset(
        'assets/images/Logo.png',
        height: 80,
        width: 200,
        fit: BoxFit.contain,
      ),
    );
  }

  static Widget getFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/Icon.png',
            height: 20,
            width: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            '© 2025 Karan Infosys. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  static Widget getPageLayout({
    required Widget child,
    required String title,
    bool showBackButton = true,
    List<Widget>? actions,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        leading: showBackButton ? null : Container(),
        actions: actions,
      ),
      body: Column(
        children: [
          // Logo at the top
          getLogo(),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
          
          // Footer at the bottom
          getFooter(),
        ],
      ),
    );
  }
} 