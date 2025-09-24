
import 'package:flutter/material.dart';

void main() {
  runApp(const AppSkeleton());
}

/// Blank skeleton for MVVM Flutter app. Implement views, viewmodels, models, and services per requirements.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini IPSC Match',
      home: Scaffold(
        body: Center(
          child: Text('TODO: Implement MVVM app skeleton'),
        ),
      ),
    );
  }
}
