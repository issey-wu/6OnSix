import 'package:flutter/material.dart';

/// Placeholder home screen. Becomes the learning path.
class HomeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('6 On Six')),
      body: Center(
        child: Text(
          'Learning path coming soon',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
