import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../data/models/journal_entry.dart';
import '../data/repositories/journal_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({
    required JournalRepository repository,
    required Connectivity connectivity,
    required String? userId,
  })  : _repository = repository,
        _connectivity = connectivity,
        _userId = userId {
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
    _init();
  }

  final JournalRepository _repository;
  final Connectivity _connectivity;
  final String? _userId;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  bool _isOffline = false;
  String? _errorMessage;

  List<JournalEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;

  Future<void> _init() async {
    await _refreshConnectivity();
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
      // ignore: unnecessary_non_null_assertion - _userId guarded by null check above
      _entries = await _repository.fetchHistoryEntries(_userId!);
    } catch (_) {
      _errorMessage = 'Unable to load history right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOffline = result.contains(ConnectivityResult.none);
    notifyListeners();
  }

  Future<void> _handleConnectivityChange(
    List<ConnectivityResult> result,
  ) async {
    final isOffline = result.contains(ConnectivityResult.none);
    _isOffline = isOffline;
    notifyListeners();
    if (!isOffline && _userId != null) {
      // ignore: unnecessary_non_null_assertion - _userId guarded by condition
      await _repository.syncPending(_userId!);
      await refresh();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
