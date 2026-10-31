import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

enum KpiTone { critical, warning, safe, info, neutral }

class StatKpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtext;
  final KpiTone tone;
  final VoidCallback? onTap;

  const StatKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtext,
    this.tone = KpiTone.neutral,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color accent;
    Color bg;

    switch (tone) {
      case KpiTone.critical:
        accent = AppColors.emergencyRed;
        bg = AppColors.emergencyRed.withOpacity(0.08);
        break;
      case KpiTone.warning:
        accent = AppColors.warningOrange;
        bg = AppColors.warningOrange.withOpacity(0.08);
        break;
      case KpiTone.safe:
        accent = AppColors.safeGreen;
        bg = AppColors.safeGreen.withOpacity(0.08);
        break;
      case KpiTone.info:
        accent = AppColors.infoCyan;
        bg = AppColors.infoCyan.withOpacity(0.08);
        break;
      case KpiTone.neutral:
        accent = isDark ? AppColors.textMuted : AppColors.textSubtle;
        bg = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9);
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: AppTheme.mono.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.textMuted : AppColors.textSubtle,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 16, color: accent),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTheme.mono.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textLight : AppColors.textDark,
              ),
            ),
            if (subtext != null) ...[
              const SizedBox(height: 2),
              Text(
                subtext!,
                style: AppTheme.sans.copyWith(
                  fontSize: 10,
                  color: isDark ? AppColors.textSubtle : AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

