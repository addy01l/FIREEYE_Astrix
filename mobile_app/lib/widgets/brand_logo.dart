import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showTagline;

  const BrandLogo({
    super.key,
    this.size = 32,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.emergencyRed.withOpacity(0.12),
            borderRadius: BorderRadius.circular(size * 0.25),
            border: Border.all(
              color: AppColors.emergencyRed.withOpacity(0.35),
              width: 1.5,
            ),
          ),
          child: Icon(
            LucideIcons.shieldAlert,
            color: AppColors.emergencyRed,
            size: size * 0.58,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConstants.appName,
              style: AppTheme.mono.copyWith(
                fontSize: size * 0.44,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: isDark ? AppColors.textLight : AppColors.textDark,
              ),
            ),
            if (showTagline)
              Text(
                'DISASTER & EMERGENCY OPERATIONS',
                style: AppTheme.mono.copyWith(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.infoCyan : AppColors.textSubtle,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

