import 'package:flutter/material.dart';

import 'app_colors.dart';

/// PLACEHOLDER type scale implementing the Display/Heading/Subheading/Body/
/// Caption hierarchy from `Mobile_UI_V1_Frozen.md` §2.2. No font family is
/// named anywhere in the repo, so this uses the platform default.
class AppTypography {
  const AppTypography._();

  static const display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const subheading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
