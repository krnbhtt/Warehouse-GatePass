import 'package:flutter/material.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Image.asset(
          'assets/images/Logo.png',
          height: 100,
          width: 260,
        ),
      ),
    );
  }
} 