import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/incident_model.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_chip.dart';
import 'create_incident_screen.dart';
import 'incident_detail_screen.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final incidentProvider = context.watch<IncidentProvider>();

    List<IncidentModel> list = incidentProvider.filteredIncidents;
    if (_searchQuery.isNotEmpty) {
      list = list.where((i) {
        return i.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            i.locationName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            i.type.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBase,
      appBar: AppBar(
        title: Text('INCIDENT REGISTRY', style: AppTheme.mono.copyWith(fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => incidentProvider.fetchIncidents(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.emergencyRed,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: Text('LOG INCIDENT', style: AppTheme.mono.copyWith(fontWeight: FontWeight.w700)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateIncidentScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCharcoal : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: AppTheme.sans.copyWith(fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by facility, sector, or disaster type...',
                    prefixIcon: const Icon(LucideIcons.search, size: 16),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterTab(
                        label: 'ALL (${incidentProvider.incidents.length})',
                        selected: incidentProvider.currentFilter == 'ALL',
                        onTap: () => incidentProvider.setFilter('ALL'),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'CRITICAL (${incidentProvider.incidents.where((i) => i.severity == "CRITICAL").length})',
                        selected: incidentProvider.currentFilter == 'CRITICAL',
                        onTap: () => incidentProvider.setFilter('CRITICAL'),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'WARNING (${incidentProvider.incidents.where((i) => i.severity == "WARNING").length})',
                        selected: incidentProvider.currentFilter == 'WARNING',
                        onTap: () => incidentProvider.setFilter('WARNING'),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'RESOLVED (${incidentProvider.incidents.where((i) => i.status == "RESOLVED").length})',
                        selected: incidentProvider.currentFilter == 'RESOLVED',
                        onTap: () => incidentProvider.setFilter('RESOLVED'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main List Content
          Expanded(
            child: incidentProvider.isLoading
                ? const LoadingView(message: 'FETCHING INCIDENT TELEMETRY...')
                : incidentProvider.errorMessage != null
                    ? ErrorStateView(
                        errorMessage: incidentProvider.errorMessage!,
                        onRetry: () => incidentProvider.fetchIncidents(),
                      )
                    : list.isEmpty
                        ? EmptyStateView(
                            title: 'NO MATCHING INCIDENTS',
                            message: 'No operational distress records found matching current query or filters.',
                            onRetry: () => incidentProvider.fetchIncidents(),
                          )
                        : RefreshIndicator(
                            onRefresh: () => incidentProvider.fetchIncidents(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              itemBuilder: (context, idx) {
                                final inc = list[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => IncidentDetailScreen(incident: inc)),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkCharcoal : AppColors.lightCard,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: inc.severity == 'CRITICAL'
                                              ? AppColors.emergencyRed.withOpacity(0.4)
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
                                                  StatusChip(label: inc.severity),
                                                  const SizedBox(width: 6),
                                                  StatusChip(label: inc.source, outlined: true),
                                                ],
                                              ),
                                              StatusChip(label: inc.status),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            inc.title,
                                            style: AppTheme.sans.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            inc.locationName,
                                            style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            inc.description,
                                            style: AppTheme.sans.copyWith(fontSize: 12, height: 1.35),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'COORDS: ${inc.latitude.toStringAsFixed(3)}, ${inc.longitude.toStringAsFixed(3)}',
                                                style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.infoCyan),
                                              ),
                                              if (inc.frp != null)
                                                Text(
                                                  'FRP: ${inc.frp} MW',
                                                  style: AppTheme.mono.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emergencyRed),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
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

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.emergencyRed : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTheme.mono.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

