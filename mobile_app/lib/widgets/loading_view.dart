import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class LoadingView extends StatelessWidget {
  final String message;

  const LoadingView({
    super.key,
    this.message = 'INITIALIZING TELEMETRY UPLINK...',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.infoCyan),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: isDark ? AppColors.textMuted : AppColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

