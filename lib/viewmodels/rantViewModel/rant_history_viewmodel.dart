import 'package:flutter/material.dart';

class RantHistoryItem {
  final String text;
  final DateTime date;

  RantHistoryItem({
    required this.text,
    required this.date,
  });
}

class RantHistoryViewModel extends ChangeNotifier {
  final List<RantHistoryItem> _items = [];

  List<RantHistoryItem> get items => List.unmodifiable(_items);

  void addRant(String text) {
    if (text.trim().isEmpty) return;

    _items.insert(
      0,
      RantHistoryItem(
        text: text,
        date: DateTime.now(),
      ),
    );

    notifyListeners();
  }
}
