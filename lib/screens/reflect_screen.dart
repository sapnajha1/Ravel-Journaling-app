import 'package:flutter/material.dart';

class ReflectScreen extends StatelessWidget {
  const ReflectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reflect')),
      body: const Center(
        child: Text('Reflect screen - implement your flow.'),
      ),
    );
  }
}
