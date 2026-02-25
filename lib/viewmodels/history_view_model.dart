import 'package:flutter/material.dart';

import '../data/models/journal_entry.dart';
import '../data/repositories/journal_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({
    required JournalRepository repository,
    required String? userId,
  })  : _repository = repository,
        _userId = userId {
    _init();
  }

  final JournalRepository _repository;
  final String? _userId;

  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<JournalEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _init() async {
    await refresh();
  }

  Future<void> refresh() async {
    if (_userId == null) {
      _entries = [];
      _errorMessage = 'Please sign in to see your history.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _entries = await _repository.fetchHistoryEntries(_userId!);
    } catch (_) {
      _errorMessage = 'Unable to load history right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
