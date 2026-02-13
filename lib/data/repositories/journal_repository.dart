import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal_entry.dart';

class JournalRepository {
  JournalRepository(this._client, this._box, this._connectivity);

  final SupabaseClient _client;
  final Box<dynamic> _box;
  final Connectivity _connectivity;

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
    await _box.put(localId, entry.toJson());

    final isOnline = await _isOnline();
    if (isOnline) {
      await _syncEntry(entry);
    }
    return entry;
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
    await _box.put(localId, entry.toJson());

    final isOnline = await _isOnline();
    if (isOnline) {
      await _syncEntry(entry);
    }
    return entry;
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
    await _box.put(localId, entry.toJson());

    final isOnline = await _isOnline();
    if (isOnline) {
      await _syncEntry(entry);
    }
    return entry;
  }

  Future<void> syncPending(String userId) async {
    final isOnline = await _isOnline();
    if (!isOnline) return;

    final entries = _box.values
        .whereType<Map>()
        .map((data) => JournalEntry.fromJson(data))
        .where((entry) => entry.userId == userId && !entry.isSynced)
        .toList();

    for (final entry in entries) {
      await _syncEntry(entry);
    }
  }

  Future<void> updateEntry(JournalEntry entry) async {
    await _box.put(entry.localId, entry.toJson());
    final isOnline = await _isOnline();
    if (isOnline && entry.remoteId != null) {
      await _updateRemoteEntry(entry);
    }
  }

  Future<void> deleteEntry(JournalEntry entry) async {
    await _box.delete(entry.localId);
    final isOnline = await _isOnline();
    final remoteId = entry.remoteId;
    if (isOnline && remoteId != null) {
      await _client
          .from('journal_entries')
          .delete()
          .match({'id': remoteId});
    }
  }

  Future<void> _updateRemoteEntry(JournalEntry entry) async {
    final remoteId = entry.remoteId;
    if (remoteId == null) return;
    await _client.from('journal_entries').update({
      'content': entry.content,
      'title': entry.title,
      'entry_date': _dateOnly(entry.entryDate),
    }).match({'id': remoteId});
  }

  String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<List<JournalEntry>> fetchHistoryEntries(String userId) async {
    final localEntries = _localEntriesForUser(userId);
    final isOnline = await _isOnline();
    if (!isOnline) {
      return _sortEntries(localEntries);
    }

    try {
      final remoteEntries = await _fetchRemoteEntries(userId);
      final unsynced = localEntries.where((entry) => !entry.isSynced).toList();
      final merged = [...remoteEntries, ...unsynced];
      return _sortEntries(merged);
    } catch (_) {
      return _sortEntries(localEntries);
    }
  }

  int pendingCount(String userId) {
    return _box.values
        .whereType<Map>()
        .map((data) => JournalEntry.fromJson(data))
        .where((entry) => entry.userId == userId && !entry.isSynced)
        .length;
  }

  List<JournalEntry> _localEntriesForUser(String userId) {
    return _box.values
        .whereType<Map>()
        .map((data) => JournalEntry.fromJson(data))
        .where((entry) => entry.userId == userId)
        .toList();
  }

  Future<List<JournalEntry>> _fetchRemoteEntries(String userId) async {
    final response = await _client
        .from('journal_entries')
        .select('id, user_id, entry_type, prompt_id, title, content, entry_date, created_at')
        .eq('user_id', userId)
        .order('entry_date', ascending: false);
    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(JournalEntry.fromRemoteJson)
        .toList();
  }

  List<JournalEntry> _sortEntries(List<JournalEntry> entries) {
    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return entries;
  }

  Future<void> _syncEntry(JournalEntry entry) async {
    try {
      final response = await _client
          .from('journal_entries')
          .insert(entry.toRemoteInsert())
          .select('id')
          .single();
      final remoteId = response['id']?.toString();
      final synced = entry.copyWith(isSynced: true, remoteId: remoteId);
      await _box.put(entry.localId, synced.toJson());
    } catch (_) {
      // Keep entry as unsynced for later retry.
    }
  }

  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
