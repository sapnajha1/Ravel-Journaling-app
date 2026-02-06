import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/rantViewModel/rant_history_viewmodel.dart';

class RantHistoryScreen extends StatelessWidget {
  const RantHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyVM = context.watch<RantHistoryViewModel>();

    if (historyVM.items.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No rants yet')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rant History')),
      body: ListView.builder(
        itemCount: historyVM.items.length,
        itemBuilder: (_, i) {
          final item = historyVM.items[i];
          return ListTile(
            title: Text(item.text),
            subtitle: Text(item.date.toString()),
          );
        },
      ),
    );
  }
}
