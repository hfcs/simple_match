import 'package:flutter/material.dart';

/// Main menu view with navigation buttons.
class MainMenuView extends StatelessWidget {
  const MainMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini IPSC Match')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('Match Setup')),
            ElevatedButton(onPressed: () {}, child: const Text('Shooter Setup')),
            ElevatedButton(onPressed: () {}, child: const Text('Stage Input')),
            ElevatedButton(onPressed: () {}, child: const Text('Clear All Data')),
          ],
        ),
      ),
    );
  }
}
