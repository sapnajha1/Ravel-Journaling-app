class JournalEntry {
  JournalEntry({
    required this.localId,
    required this.userId,
    required this.entryType,
    this.promptId,
    required this.content,
    required this.entryDate,
    this.title,
    this.isSynced = false,
    this.remoteId,
    this.createdTimestamp,
  });

  final String localId;
  final String userId;
  final String entryType;
  final String? promptId;
  final String? title;
  final String content;
  final DateTime entryDate;
  final bool isSynced;
  final String? remoteId;
  /// Creation time from database (e.g. created_at / created_timestamp). Used for display on history card.
  final DateTime? createdTimestamp;

  JournalEntry copyWith({
    String? localId,
    String? userId,
    String? entryType,
    String? promptId,
    String? title,
    String? content,
    DateTime? entryDate,
    bool? isSynced,
    String? remoteId,
    DateTime? createdTimestamp,
  }) {
    return JournalEntry(
      localId: localId ?? this.localId,
      userId: userId ?? this.userId,
      entryType: entryType ?? this.entryType,
      promptId: promptId ?? this.promptId,
      title: title ?? this.title,
      content: content ?? this.content,
      entryDate: entryDate ?? this.entryDate,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
      createdTimestamp: createdTimestamp ?? this.createdTimestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'local_id': localId,
        'user_id': userId,
        'entry_type': entryType,
        'prompt_id': promptId,
        'title': title,
        'content': content,
        'entry_date': entryDate.toIso8601String(),
        'is_synced': isSynced,
        'remote_id': remoteId,
        'created_timestamp': createdTimestamp?.toIso8601String(),
      };

  Map<String, dynamic> toRemoteInsert() => {
        'user_id': userId,
        'entry_type': entryType,
        'prompt_id': promptId,
        'title': title,
        'content': content,
        'entry_date': _dateOnly(entryDate),
      };

  String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  factory JournalEntry.fromJson(Map<dynamic, dynamic> json) {
    return JournalEntry(
      localId: (json['local_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      entryType: (json['entry_type'] ?? '').toString(),
      promptId: json['prompt_id']?.toString(),
      title: json['title']?.toString(),
      content: (json['content'] ?? '').toString(),
      entryDate: DateTime.tryParse(json['entry_date']?.toString() ?? '') ??
          DateTime.now(),
      isSynced: json['is_synced'] == true,
      remoteId: json['remote_id']?.toString(),
      createdTimestamp: _parseTimestamp(
          json['created_timestamp'] ?? json['created_at'] ?? json['createdTimestamp']),
    );
  }

  factory JournalEntry.fromRemoteJson(Map<String, dynamic> json) {
    final remoteId = json['id']?.toString();
    return JournalEntry(
      localId: 'remote_${remoteId ?? DateTime.now().microsecondsSinceEpoch}',
      userId: (json['user_id'] ?? '').toString(),
      entryType: (json['entry_type'] ?? '').toString(),
      promptId: json['prompt_id']?.toString(),
      title: json['title']?.toString(),
      content: (json['content'] ?? '').toString(),
      entryDate: DateTime.tryParse(json['entry_date']?.toString() ?? '') ??
          DateTime.now(),
      isSynced: true,
      remoteId: remoteId,
      createdTimestamp: _parseTimestamp(
          json['created_at'] ?? json['created_timestamp'] ?? json['createdTimestamp']),
    );
  }
}
