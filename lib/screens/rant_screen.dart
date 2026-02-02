import 'package:flutter/material.dart';

class RantScreen extends StatelessWidget {
  const RantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rant')),
      body: const Center(
        child: Text('Rant screen - implement your flow.'),
      ),
    );
  }
}
