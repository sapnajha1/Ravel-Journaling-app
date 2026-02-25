import 'package:hive_flutter/hive_flutter.dart';

class LocalStore {
  LocalStore._();

  static const String promptsBox = 'prompts';
  static const String journalEntriesBox = 'journal_entries';
  static const String appSettingsBoxName = 'app_settings';

  // Analysis preference: 'always' | 'ask' | 'never'
  static const String analysisPreferenceKey = 'analysis_preference';
  static const String analysisPreferenceAlways = 'always';
  static const String analysisPreferenceAsk = 'ask';
  static const String analysisPreferenceNever = 'never';

  // Whether the analysis permission screen has been shown to the user
  static const String analysisPermissionShownKey = 'analysis_permission_shown';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(promptsBox);
    await Hive.openBox<dynamic>(journalEntriesBox);
    await Hive.openBox<dynamic>(appSettingsBoxName);
  }

  static Box<dynamic> promptBox() => Hive.box<dynamic>(promptsBox);
  static Box<dynamic> journalBox() => Hive.box<dynamic>(journalEntriesBox);
  static Box<dynamic> appSettingsBox() => Hive.box<dynamic>(appSettingsBoxName);
}
