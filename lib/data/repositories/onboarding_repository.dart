import 'package:hive/hive.dart';

class OnboardingRepository {
  OnboardingRepository(this._box);

  static const String onboardingKey = 'onboarding_completed';

  final Box<dynamic> _box;

  bool get isCompleted => _box.get(onboardingKey, defaultValue: false) as bool;

  Future<void> setCompleted() async {
    await _box.put(onboardingKey, true);
  }
}
