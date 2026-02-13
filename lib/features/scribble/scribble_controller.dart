import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/journal_repository.dart';
import '../../features/reflect/reflect_controller.dart';

class ScribbleState {
  const ScribbleState({
    this.isSaving = false,
    this.errorMessage,
  });

  final bool isSaving;
  final String? errorMessage;

  ScribbleState copyWith({bool? isSaving, String? errorMessage}) {
    return ScribbleState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

final scribbleControllerProvider =
    StateNotifierProvider.autoDispose<ScribbleController, ScribbleState>(
  (ref) => ScribbleController(ref.read(journalRepositoryProvider)),
);

class ScribbleController extends StateNotifier<ScribbleState> {
  ScribbleController(this._journalRepository) : super(const ScribbleState());

  final JournalRepository _journalRepository;

  /// Saves scribble image as base64 PNG. Returns true on success.
  Future<bool> saveScribble({
    required String contentBase64,
    DateTime? entryDate,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(
        errorMessage: 'Please sign in to save your scribble.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _journalRepository.saveScribbleEntry(
        userId: userId,
        content: contentBase64,
        entryDate: entryDate,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Unable to save your scribble right now.',
      );
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
