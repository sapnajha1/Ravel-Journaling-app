import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/local_store.dart';
import '../../data/models/prompt.dart';
import '../../data/repositories/journal_repository.dart';
import '../../data/repositories/prompt_repository.dart';

class ReflectState {
  const ReflectState({
    this.isLoading = false,
    this.isSaving = false,
    this.isOffline = false,
    this.showSaved = false,
    this.pendingSyncCount = 0,
    this.prompt,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final bool isOffline;
  final bool showSaved;
  final int pendingSyncCount;
  final Prompt? prompt;
  final String? errorMessage;

  ReflectState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isOffline,
    bool? showSaved,
    int? pendingSyncCount,
    Prompt? prompt,
    String? errorMessage,
  }) {
    return ReflectState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isOffline: isOffline ?? this.isOffline,
      showSaved: showSaved ?? this.showSaved,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      prompt: prompt ?? this.prompt,
      errorMessage: errorMessage,
    );
  }
}

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final promptBoxProvider = Provider<Box<dynamic>>(
  (ref) => LocalStore.promptBox(),
);

final journalBoxProvider = Provider<Box<dynamic>>(
  (ref) => LocalStore.journalBox(),
);

final promptRepositoryProvider = Provider<PromptRepository>((ref) {
  return PromptRepository(
    ref.read(supabaseClientProvider),
    ref.read(promptBoxProvider),
  );
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(
    ref.read(supabaseClientProvider),
    ref.read(journalBoxProvider),
    ref.read(connectivityProvider),
  );
});

final reflectControllerProvider =
    StateNotifierProvider.autoDispose<ReflectController, ReflectState>(
  (ref) => ReflectController(
    ref.read(promptRepositoryProvider),
    ref.read(journalRepositoryProvider),
    ref.read(connectivityProvider),
  ),
);

class ReflectController extends StateNotifier<ReflectState> {
  ReflectController(this._promptRepository, this._journalRepository,
      this._connectivity)
      : super(const ReflectState()) {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (result) => _handleConnectivityChange(result),
    );
    _init();
  }

  final PromptRepository _promptRepository;
  final JournalRepository _journalRepository;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> _init() async {
    await _refreshConnectivity();
    await loadPrompt();
    await refreshPendingCount();
    _warmPromptCache();
  }

  Future<void> _refreshConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    final isOffline = result.contains(ConnectivityResult.none);
    state = state.copyWith(isOffline: isOffline);
  }

  Future<void> loadPrompt() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final prompt = await _promptRepository.fetchNextReflectionPrompt();
      state = state.copyWith(prompt: prompt);
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Unable to load prompt. Please try again.',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> changePrompt() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final prompt = await _promptRepository.fetchNextReflectionPrompt(
        excludeId: state.prompt?.id,
      );
      state = state.copyWith(prompt: prompt);
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Unable to change prompt right now.',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _warmPromptCache() async {
    try {
      await _promptRepository.refreshReflectionPrompts();
    } catch (_) {
      // Ignore cache refresh failures; cached prompts will remain.
    }
  }

  void clearPrompt() {
    state = state.copyWith(prompt: null);
  }

  Future<bool> saveEntry({
    required String content,
    String? title,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(
        errorMessage: 'Please sign in to save your reflection.',
      );
      return false;
    }
    final promptId = state.prompt?.id;

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _journalRepository.saveReflectionEntry(
        userId: userId,
        promptId: promptId,
        content: content,
        title: title,
      );
      await refreshPendingCount();
      state = state.copyWith(showSaved: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Unable to save your reflection right now.',
      );
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> refreshPendingCount() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final count = _journalRepository.pendingCount(userId);
    state = state.copyWith(pendingSyncCount: count);
  }

  Future<void> _handleConnectivityChange(
    List<ConnectivityResult> result,
  ) async {
    final isOffline = result.contains(ConnectivityResult.none);
    state = state.copyWith(isOffline: isOffline);
    if (!isOffline) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await _journalRepository.syncPending(userId);
        await refreshPendingCount();
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
