import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A circular avatar showing a name's first initial — matches the case
/// card style described in `Mobile_UI_V1_Frozen.md` §6.1 ("avatar initial,
/// customer name, outstanding amount, a status pill, a risk badge"),
/// reused here for the Customer List/Details cards.
class AvatarInitial extends StatelessWidget {
  final String name;
  final double radius;

  const AvatarInitial({super.key, required this.name, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        initial,
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: radius * 0.82),
      ),
    );
  }
}
