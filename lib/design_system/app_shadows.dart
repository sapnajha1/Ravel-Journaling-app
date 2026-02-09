import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static const BoxShadow shadow7 = BoxShadow(
    color: AppColors.textPrimary,
    offset: Offset(4, 7),
    blurRadius: 0,
  );

  static const BoxShadow shadow5 = BoxShadow(
    color: AppColors.textPrimary,
    offset: Offset(3, 5),
    blurRadius: 0,
  );

  static const BoxShadow shadow2 = BoxShadow(
    color: AppColors.textPrimary,
    offset: Offset(2, 2),
    blurRadius: 0,
  );

  static const BoxShadow shadow5Vertical = BoxShadow(
    color: AppColors.textPrimary,
    offset: Offset(0, 5),
    blurRadius: 0,
  );
}
