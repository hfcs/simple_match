import 'package:flutter/material.dart';

/// Match setup view skeleton.
class MatchSetupView extends StatelessWidget {
  const MatchSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match Setup')),
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('Match Setup'),
          SizedBox(height: 16),
          Text('TODO: Implement Match Setup UI'),
        ],
      )),
    );
  }
}
