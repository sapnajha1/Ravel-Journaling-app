import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/local_store.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/prompt.dart';
import '../../data/repositories/journal_repository.dart';
import '../../data/repositories/prompt_repository.dart';

class ReflectState {
  const ReflectState({
    this.isLoading = false,
    this.isSaving = false,
    this.showSaved = false,
    this.prompt,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final bool showSaved;
  final Prompt? prompt;
  final String? errorMessage;

  ReflectState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? showSaved,
    Prompt? prompt,
    String? errorMessage,
  }) {
    return ReflectState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      showSaved: showSaved ?? this.showSaved,
      prompt: prompt ?? this.prompt,
      errorMessage: errorMessage,
    );
  }
}

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

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
  );
});

final reflectControllerProvider =
    StateNotifierProvider.autoDispose<ReflectController, ReflectState>(
  (ref) => ReflectController(
    ref.read(promptRepositoryProvider),
    ref.read(journalRepositoryProvider),
  ),
);

class ReflectController extends StateNotifier<ReflectState> {
  ReflectController(this._promptRepository, this._journalRepository)
      : super(const ReflectState()) {
    _init();
  }

  final PromptRepository _promptRepository;
  final JournalRepository _journalRepository;

  Future<void> _init() async {
    await loadPrompt();
    _warmPromptCache();
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
    state = ReflectState(
      isLoading: state.isLoading,
      isSaving: state.isSaving,
      showSaved: state.showSaved,
      prompt: null,
      errorMessage: state.errorMessage,
    );
  }

  /// Call after "Reflect Again" to show the editor again and optionally load a new prompt.
  Future<void> resetForNewReflection({bool loadNewPrompt = true}) async {
    state = state.copyWith(showSaved: false);
    if (loadNewPrompt) await loadPrompt();
  }

  /// Saves the reflection entry and returns the saved [JournalEntry], or null on failure.
  Future<JournalEntry?> saveEntry({
    required String content,
    String? title,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(
        errorMessage: 'Please sign in to save your reflection.',
      );
      return null;
    }
    final promptId = state.prompt?.id;

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final entry = await _journalRepository.saveReflectionEntry(
        userId: userId,
        promptId: promptId,
        content: content,
        title: title,
      );
      return entry;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Unable to save your reflection right now.',
      );
      return null;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
