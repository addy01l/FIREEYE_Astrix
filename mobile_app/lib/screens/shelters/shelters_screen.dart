import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/shelter_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_chip.dart';

class SheltersScreen extends StatefulWidget {
  const SheltersScreen({super.key});

  @override
  State<SheltersScreen> createState() => _SheltersScreenState();
}

class _SheltersScreenState extends State<SheltersScreen> {
  bool _filterAvailableOnly = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shelterProvider = context.watch<ShelterProvider>();

    var list = shelterProvider.shelters;
    if (_filterAvailableOnly) {
      list = list.where((s) => s.availableBeds > 0).toList();
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBase,
      appBar: AppBar(
        title: Text('EMERGENCY SHELTERS', style: AppTheme.mono.copyWith(fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => shelterProvider.fetchShelters(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Capacity Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCharcoal : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL BED CAPACITY: ${shelterProvider.totalCapacity}',
                      style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${shelterProvider.totalAvailable} beds currently unoccupied',
                      style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.safeGreen),
                    ),
                  ],
                ),
                FilterChip(
                  label: Text('Available Only', style: AppTheme.mono.copyWith(fontSize: 10)),
                  selected: _filterAvailableOnly,
                  onSelected: (val) => setState(() => _filterAvailableOnly = val),
                ),
              ],
            ),
          ),

          // Shelters List
          Expanded(
            child: shelterProvider.isLoading
                ? const LoadingView(message: 'FETCHING SHELTER DIRECTORY...')
                : list.isEmpty
                    ? EmptyStateView(
                        title: 'NO SHELTERS FOUND',
                        message: 'No designated relief shelters matching filters.',
                        onRetry: () => shelterProvider.fetchShelters(),
                      )
                    : RefreshIndicator(
                        onRefresh: () => shelterProvider.fetchShelters(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (context, idx) {
                            final s = list[idx];
                            final pct = s.occupancyRate;
                            final isNearCap = pct >= 0.85;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCharcoal : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isNearCap
                                      ? AppColors.warningOrange.withOpacity(0.5)
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.tent, size: 16, color: AppColors.safeGreen),
                                          const SizedBox(width: 8),
                                          Text(s.id, style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.textMuted)),
                                        ],
                                      ),
                                      StatusChip(
                                        label: s.status,
                                        color: isNearCap ? AppColors.warningOrange : AppColors.safeGreen,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    s.name,
                                    style: AppTheme.sans.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    s.address,
                                    style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 12),

                                  // Occupancy Progress
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Occupancy: ${s.occupancy} / ${s.capacity}',
                                        style: AppTheme.mono.copyWith(fontSize: 11),
                                      ),
                                      Text(
                                        '${s.availableBeds} Available',
                                        style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.safeGreen),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 6,
                                      backgroundColor: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE2E8F0),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isNearCap ? AppColors.warningOrange : AppColors.safeGreen,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Features / Amenities
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      if (s.hasMedical)
                                        _AmenityChip(label: 'Medical Post', icon: LucideIcons.heartPulse),
                                      if (s.hasGenerator)
                                        _AmenityChip(label: 'Power Backup', icon: LucideIcons.zap),
                                      _AmenityChip(label: 'Food Rations', icon: LucideIcons.utensils),
                                      _AmenityChip(label: 'Drinking Water', icon: LucideIcons.droplets),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Contact: ${s.contactPhone}', style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted)),
                                      Text('GPS: ${s.latitude.toStringAsFixed(3)}, ${s.longitude.toStringAsFixed(3)}', style: AppTheme.mono.copyWith(fontSize: 9, color: AppColors.infoCyan)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _AmenityChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.infoCyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.infoCyan.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.infoCyan),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.mono.copyWith(fontSize: 9, color: AppColors.infoCyan)),
        ],
      ),
    );
  }
}

