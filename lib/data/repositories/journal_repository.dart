import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal_entry.dart';

class JournalRepository {
  JournalRepository(this._client, this._box);

  final SupabaseClient _client;
  final Box<dynamic> _box;

  Future<JournalEntry> saveReflectionEntry({
    required String userId,
    String? promptId,
    required String content,
    String? title,
    DateTime? entryDate,
  }) async {
    final localId = '${userId}_${DateTime.now().microsecondsSinceEpoch}';
    final entry = JournalEntry(
      localId: localId,
      userId: userId,
      entryType: 'reflection',
      promptId: promptId,
      title: title?.trim().isEmpty == true ? null : title?.trim(),
      content: content,
      entryDate: entryDate ?? DateTime.now(),
      isSynced: false,
    );

    // INSERT directly to Supabase and get remoteId back.
    final remoteId = await _insertRemote(entry);
    final synced = entry.copyWith(isSynced: true, remoteId: remoteId);
    await _box.put(localId, synced.toJson());
    return synced;
  }

  Future<JournalEntry> saveRantEntry({
    required String userId,
    required String content,
    String? title,
    DateTime? entryDate,
  }) async {
    final localId = '${userId}_${DateTime.now().microsecondsSinceEpoch}';
    final entry = JournalEntry(
      localId: localId,
      userId: userId,
      entryType: 'rant',
      title: title?.trim().isEmpty == true ? null : title?.trim(),
      content: content,
      entryDate: entryDate ?? DateTime.now(),
      isSynced: false,
    );

    final remoteId = await _insertRemote(entry);
    final synced = entry.copyWith(isSynced: true, remoteId: remoteId);
    await _box.put(localId, synced.toJson());
    return synced;
  }

  /// Saves a scribble entry. [content] is the base64-encoded PNG image data.
  Future<JournalEntry> saveScribbleEntry({
    required String userId,
    required String content,
    DateTime? entryDate,
  }) async {
    final localId = '${userId}_${DateTime.now().microsecondsSinceEpoch}';
    final entry = JournalEntry(
      localId: localId,
      userId: userId,
      entryType: 'scribble',
      content: content,
      entryDate: entryDate ?? DateTime.now(),
      isSynced: false,
    );

    final remoteId = await _insertRemote(entry);
    final synced = entry.copyWith(isSynced: true, remoteId: remoteId);
    await _box.put(localId, synced.toJson());
    return synced;
  }

  Future<void> updateEntry(JournalEntry entry) async {
    await _box.put(entry.localId, entry.toJson());
    if (entry.remoteId != null) {
      await _updateRemoteEntry(entry);
    }
  }

  Future<void> deleteEntry(JournalEntry entry) async {
    await _box.delete(entry.localId);
    final remoteId = entry.remoteId;
    if (remoteId != null) {
      await _client
          .from('journal_entries')
          .delete()
          .match({'id': remoteId});
    }
  }

  Future<List<JournalEntry>> fetchHistoryEntries(String userId) async {
    try {
      final remoteEntries = await _fetchRemoteEntries(userId);
      // Prefer local Hive version when available (it may have moods/insight/topics
      // that haven't been persisted to the remote yet via updateEntry).
      final localByRemoteId = {
        for (final e in _localEntriesForUser(userId))
          if (e.remoteId != null) e.remoteId!: e,
      };
      final merged = remoteEntries
          .map((r) => localByRemoteId[r.remoteId] ?? r)
          .toList();
      // Dedup by localId as a safety guard.
      final seen = <String>{};
      return _sortEntries(merged.where((e) => seen.add(e.localId)).toList());
    } catch (e, st) {
      debugPrint('[JournalRepository] Fetch remote failed: $e');
      debugPrint('[JournalRepository] Stack: $st');
      // Fall back to local Hive cache on error.
      return _sortEntries(_localEntriesForUser(userId));
    }
  }

  Future<void> _updateRemoteEntry(JournalEntry entry) async {
    final remoteId = entry.remoteId;
    if (remoteId == null) return;
    final payload = <String, dynamic>{
      'content': entry.content,
      'title': entry.title,
      'entry_date': _dateOnly(entry.entryDate),
    };
    if (entry.moods != null) payload['moods'] = entry.moods!.join('||');
    if (entry.insight != null) payload['insight'] = entry.insight;
    if (entry.topics != null) payload['topics'] = entry.topics!.join('||');
    await _client.from('journal_entries').update(payload).match({'id': remoteId});
  }

  Future<String?> _insertRemote(JournalEntry entry) async {
    try {
      final response = await _client
          .from('journal_entries')
          .insert(entry.toRemoteInsert())
          .select('id')
          .single();
      return response['id']?.toString();
    } catch (e, st) {
      debugPrint('[JournalRepository] Insert failed (${entry.entryType}): $e');
      debugPrint('[JournalRepository] Stack: $st');
      rethrow;
    }
  }

  String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<List<JournalEntry>> _fetchRemoteEntries(String userId) async {
    final response = await _client
        .from('journal_entries')
        .select(
          'id, user_id, entry_type, prompt_id, title, content, entry_date, '
          'created_at, moods, insight, topics',
        )
        .eq('user_id', userId)
        .order('entry_date', ascending: false);
    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(JournalEntry.fromRemoteJson)
        .toList();
  }

  List<JournalEntry> _localEntriesForUser(String userId) {
    return _box.values
        .whereType<Map>()
        .map((data) => JournalEntry.fromJson(data))
        .where((entry) => entry.userId == userId)
        .toList();
  }

  List<JournalEntry> _sortEntries(List<JournalEntry> entries) {
    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return entries;
  }
}
