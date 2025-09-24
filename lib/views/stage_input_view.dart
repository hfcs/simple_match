import 'package:flutter/material.dart';

/// Stage input view skeleton.
class StageInputView extends StatelessWidget {
  const StageInputView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stage Input')),
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('Stage Input'),
          SizedBox(height: 16),
          Text('TODO: Implement Stage Input UI'),
        ],
      )),
    );
  }
}
