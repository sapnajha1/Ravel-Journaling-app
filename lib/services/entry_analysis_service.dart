import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/entry_analysis.dart';

/// Maps Yale Mood Meter labels to best-fit emoji.
/// If a label isn't in this map, no emoji is shown.
const Map<String, String> _moodEmojiMap = {
  // Red — unpleasant/high energy
  'Enraged': '🤬', 'Panicked': '😱', 'Stressed': '😖', 'Jittery': '😬',
  'Livid': '😡', 'Furious': '😡', 'Frustrated': '😤', 'Tense': '😬',
  'Fuming': '😤', 'Frightened': '😨', 'Angry': '😠', 'Nervous': '😰',
  'Restless': '😟', 'Anxious': '😰', 'Apprehensive': '😟', 'Worried': '😟',
  'Irritated': '😒', 'Annoyed': '😒', 'Repulsed': '🤢', 'Troubled': '😟',
  'Concerned': '😟', 'Uneasy': '😬', 'Peeved': '😒', 'Disgusted': '🤢',
  // Yellow — pleasant/high energy
  'Shocked': '😲', 'Surprised': '😮', 'Upbeat': '😊', 'Festive': '🎉',
  'Hyper': '⚡', 'Cheerful': '😄', 'Motivated': '💪', 'Inspired': '✨',
  'Elated': '😄', 'Lively': '🌟', 'Excited': '🎉', 'Optimistic': '🌟',
  'Enthusiastic': '🙌', 'Energized': '⚡', 'Thrilled': '🤩', 'Happy': '😊',
  'Proud': '🦁', 'Focused': '🎯', 'Exhilarated': '🤩', 'Ecstatic': '🤩',
  'Joyful': '😄', 'Playful': '😜', 'Blissful': '😌', 'Hopeful': '🌈',
  'Pleased': '😊',
  // Green — pleasant/low energy
  'At Ease': '😌', 'Easygoing': '😌', 'Content': '☺️', 'Loving': '🥰',
  'Fulfilled': '😌', 'Calm': '🧘', 'Secure': '🛡️', 'Satisfied': '😌',
  'Grateful': '🙏', 'Touched': '🥹',
  // Blue — unpleasant/low energy
  'Apathetic': '😑', 'Down': '😔', 'Sad': '😢', 'Bored': '😑',
  'Discouraged': '😔', 'Morose': '😞', 'Pessimistic': '😞', 'Glum': '😔',
  'Disappointed': '😞', 'Alienated': '😶', 'Disheartened': '😞',
  'Miserable': '😢', 'Lonely': '😢',
};

String _emojiForMood(String label) => _moodEmojiMap[label] ?? '';

class EntryAnalysisService {
  /// Calls the `generate-followup` Supabase Edge Function and returns a
  /// follow-up question string. Falls back to a default prompt on any error.
  Future<String> generateFollowUp(String content) async {
    try {
      final supabase = Supabase.instance.client;
      debugPrint('[generate-followup] Invoking Edge Function');

      final response = await supabase.functions.invoke(
        'generate-followup',
        body: {'content': content},
      );

      debugPrint('[generate-followup] Status: ${response.status}');

      if (response.status != 200) {
        debugPrint('[generate-followup] Non-200 response: ${response.data}');
        return "What else is on your mind?";
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return "What else is on your mind?";
      }

      final followUp = data['followUp'];
      if (followUp is! String || followUp.trim().isEmpty) {
        return "What else is on your mind?";
      }

      return followUp.trim();
    } catch (e, stack) {
      debugPrint('[generate-followup] Error: $e\n$stack');
      return "What else is on your mind?";
    }
  }

  /// Calls the `analyze-entry` Supabase Edge Function and returns an
  /// [EntryAnalysis]. Returns [EntryAnalysis.fallback()] on any error so the
  /// caller always receives a usable object.
  Future<EntryAnalysis> analyzeEntry(String content, String entryType) async {
    try {
      final supabase = Supabase.instance.client;
      debugPrint('[analyze-entry] Invoking Edge Function, entryType=$entryType');

      final response = await supabase.functions.invoke(
        'analyze-entry',
        body: {'content': content, 'entryType': entryType},
      );

      debugPrint('[analyze-entry] Status: ${response.status}');

      if (response.status != 200) {
        debugPrint('[analyze-entry] Non-200 response: ${response.data}');
        return EntryAnalysis.fallback();
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        debugPrint('[analyze-entry] Unexpected data type: ${data.runtimeType}');
        return EntryAnalysis.fallback();
      }

      return EntryAnalysis.fromJson(data, _emojiForMood);
    } catch (e, stack) {
      debugPrint('[analyze-entry] Error: $e\n$stack');
      return EntryAnalysis.fallback();
    }
  }
}
