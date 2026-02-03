import 'package:hive_flutter/hive_flutter.dart';

class LocalStore {
  LocalStore._();

  static const String promptsBox = 'prompts';
  static const String journalEntriesBox = 'journal_entries';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(promptsBox);
    await Hive.openBox<dynamic>(journalEntriesBox);
  }

  static Box<dynamic> promptBox() => Hive.box<dynamic>(promptsBox);
  static Box<dynamic> journalBox() => Hive.box<dynamic>(journalEntriesBox);
}
