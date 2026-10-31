import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = LucideIcons.inbox,
    this.onRetry,
    this.retryLabel = 'RELOAD',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: isDark ? AppColors.textSubtle : AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.mono.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textLight : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.sans.copyWith(
                fontSize: 12,
                color: isDark ? AppColors.textSubtle : AppColors.textMuted,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.refreshCw, size: 14),
                label: Text(retryLabel),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

