import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool outlined;

  const StatusChip({
    super.key,
    required this.label,
    this.color,
    this.outlined = false,
  });

  Color _resolveColor() {
    if (color != null) return color!;
    final upper = label.toUpperCase();
    if (upper.contains('CRITICAL') || upper.contains('FIRE') || upper.contains('TRAPPED')) {
      return AppColors.emergencyRed;
    }
    if (upper.contains('WARNING') || upper.contains('DISPATCHED') || upper.contains('TRANSIT')) {
      return AppColors.warningOrange;
    }
    if (upper.contains('SAFE') || upper.contains('RESOLVED') || upper.contains('READY') || upper.contains('RESCUED')) {
      return AppColors.safeGreen;
    }
    if (upper.contains('WATCH') || upper.contains('ACTIVE') || upper.contains('INFO') || upper.contains('LIVE')) {
      return AppColors.infoCyan;
    }
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = _resolveColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : chipColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: chipColor.withOpacity(outlined ? 0.7 : 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.mono.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: chipColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

