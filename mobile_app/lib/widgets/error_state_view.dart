import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class ErrorStateView extends StatelessWidget {
  final String title;
  final String errorMessage;
  final VoidCallback? onRetry;

  const ErrorStateView({
    super.key,
    this.title = 'OPERATIONAL TELEMETRY ERROR',
    required this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.emergencyRed.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.emergencyRed.withOpacity(0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertTriangle, size: 36, color: AppColors.emergencyRed),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTheme.mono.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emergencyRed,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: AppTheme.sans.copyWith(
                  fontSize: 12,
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (onRetry != null)
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                  label: const Text('RETRY REQUEST'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergencyRed,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: onRetry,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

