import 'package:flutter/material.dart';

/// Overall result view skeleton.
class OverallResultView extends StatelessWidget {
  const OverallResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overall Result')),
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(height: 16),
          Text('TODO: Implement Overall Result UI'),
        ],
      )),
    );
  }
}
