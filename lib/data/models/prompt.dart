class Prompt {
  Prompt({
    required this.id,
    required this.text,
    required this.category,
  });

  final String id;
  final String text;
  final String category;

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'].toString(),
      text: (json['text'] ??
              json['prompt_text'] ??
              json['prompt'] ??
              json['content'] ??
              '')
          .toString(),
      category: (json['category'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'category': category,
      };
}
