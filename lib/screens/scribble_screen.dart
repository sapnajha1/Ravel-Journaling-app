import 'package:flutter/material.dart';

class ScribbleScreen extends StatelessWidget {
  const ScribbleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scribble')),
      body: const Center(
        child: Text('Scribble screen - implement your flow.'),
      ),
    );
  }
}
