import 'package:hive/hive.dart';

import '../../domain/repositories/onboarding_repository.dart' as domain;

class OnboardingRepository implements domain.OnboardingRepository {
  OnboardingRepository(this._box);

  static const String onboardingKey = 'onboarding_completed';

  final Box<dynamic> _box;

  @override
  Future<bool> isCompleted() async =>
      _box.get(onboardingKey, defaultValue: false) as bool;

  @override
  Future<void> setCompleted() async {
    await _box.put(onboardingKey, true);
  }
}
