class MoodTag {
  const MoodTag({required this.emoji, required this.label});

  final String emoji;
  final String label;
}

class EntryAnalysis {
  const EntryAnalysis({
    required this.title,
    required this.moods,
    required this.insight,
    required this.topics,
  });

  final String title;
  final List<MoodTag> moods;
  final String insight;
  final List<String> topics;

  /// Fallback used when the AI call fails — shows empty/placeholder content.
  factory EntryAnalysis.fallback() => const EntryAnalysis(
        title: '',
        moods: [],
        insight: '',
        topics: [],
      );

  factory EntryAnalysis.fromJson(
    Map<String, dynamic> json,
    String Function(String label) emojiForMood,
  ) {
    final rawMoods = (json['moods'] as List?)?.cast<String>() ?? [];
    final moods = rawMoods.map((label) {
      final emoji = emojiForMood(label);
      return MoodTag(emoji: emoji, label: label);
    }).toList();

    return EntryAnalysis(
      title: (json['title'] as String?) ?? '',
      moods: moods,
      insight: (json['insight'] as String?) ?? '',
      topics: (json['topics'] as List?)?.cast<String>() ?? [],
    );
  }
}
