import 'package:flutter/material.dart';

/// Shooter setup view skeleton.
class ShooterSetupView extends StatelessWidget {
  const ShooterSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shooter Setup')),
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(height: 16),
          Text('TODO: Implement Shooter Setup UI'),
        ],
      )),
    );
  }
}
