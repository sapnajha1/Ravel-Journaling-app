import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/onboarding_repository.dart';

class SharedPrefsOnboardingRepository implements OnboardingRepository {
  SharedPrefsOnboardingRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'onboarding_completed';

  @override
  Future<bool> isCompleted() async {
    return _prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> setCompleted() async {
    await _prefs.setBool(_key, true);
  }
}
