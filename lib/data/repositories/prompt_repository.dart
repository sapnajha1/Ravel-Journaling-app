import 'dart:math';

import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/prompt.dart';

class PromptRepository {
  PromptRepository(this._client, this._box);

  final SupabaseClient _client;
  final Box<dynamic> _box;

  static const String _reflectionKey = 'reflection_prompts';

  Future<Prompt> fetchNextReflectionPrompt({String? excludeId}) async {
    List<Prompt> prompts = _loadCachedPrompts();
    if (prompts.isEmpty) {
      try {
        prompts = await _fetchRemoteReflectionPrompts();
        await _cachePrompts(prompts);
      } catch (_) {
        prompts = _loadCachedPrompts();
      }
    }

    if (prompts.isEmpty) {
      return Prompt(
        id: 'default-reflection',
        text: "What's something that brought a smile to your face today?",
        category: 'reflection',
      );
    }

    final available =
        prompts.where((prompt) => prompt.id != excludeId).toList();
    final candidates = available.isEmpty ? prompts : available;
    return candidates[Random().nextInt(candidates.length)];
  }

  List<Prompt> _loadCachedPrompts() {
    final stored = _box.get(_reflectionKey);
    if (stored is List) {
      return stored
          .whereType<Map>()
          .map((item) => Prompt.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<void> _cachePrompts(List<Prompt> prompts) async {
    final payload = prompts.map((prompt) => prompt.toJson()).toList();
    await _box.put(_reflectionKey, payload);
  }

  List<Prompt> getCachedReflectionPrompts() {
    return _loadCachedPrompts();
  }

  Future<void> refreshReflectionPrompts() async {
    final prompts = await _fetchRemoteReflectionPrompts();
    await _cachePrompts(prompts);
  }

  Future<List<Prompt>> _fetchRemoteReflectionPrompts() async {
    final response = await _client
        .from('reflection_prompts')
        .select()
        .eq('is_active', true);
    final data = (response as List)
        .map((row) => Prompt.fromJson(Map<String, dynamic>.from(row)))
        .where((prompt) => prompt.text.trim().isNotEmpty)
        .toList();
    return data;
  }
}
