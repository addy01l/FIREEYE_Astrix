import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/rescue_center_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_chip.dart';

class RescueCentersScreen extends StatelessWidget {
  const RescueCentersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rescueProvider = context.watch<RescueCenterProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBase,
      appBar: AppBar(
        title: Text('RESCUE BASES & STATIONS', style: AppTheme.mono.copyWith(fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => rescueProvider.fetchRescueCenters(),
          ),
        ],
      ),
      body: rescueProvider.isLoading
          ? const LoadingView(message: 'FETCHING RESCUE STATION DATA...')
          : rescueProvider.centers.isEmpty
              ? EmptyStateView(
                  title: 'NO RESCUE POSTS FOUND',
                  message: 'No operational rescue posts or SDRF stations reported by backend.',
                  onRetry: () => rescueProvider.fetchRescueCenters(),
                )
              : RefreshIndicator(
                  onRefresh: () => rescueProvider.fetchRescueCenters(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rescueProvider.centers.length,
                    itemBuilder: (context, idx) {
                      final rc = rescueProvider.centers[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCharcoal : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.truck, size: 16, color: AppColors.infoBlue),
                                    const SizedBox(width: 8),
                                    Text(
                                      rc.id,
                                      style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.infoCyan),
                                    ),
                                  ],
                                ),
                                StatusChip(label: rc.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rc.name,
                              style: AppTheme.sans.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              rc.location,
                              style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _InfoCol(label: 'ASSIGNED UNIT', val: rc.stationUnit),
                                  _InfoCol(label: 'PERSONNEL', val: '${rc.activePersonnel} active'),
                                  _InfoCol(label: 'FLEET', val: '${rc.availableVehicles} vehicles'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.phone, size: 12, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text(rc.contactPhone, style: AppTheme.mono.copyWith(fontSize: 11)),
                                  ],
                                ),
                                Text(
                                  'GPS: ${rc.latitude.toStringAsFixed(3)}, ${rc.longitude.toStringAsFixed(3)}',
                                  style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.infoCyan),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  final String label;
  final String val;

  const _InfoCol({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTheme.mono.copyWith(fontSize: 8, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(val, style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

