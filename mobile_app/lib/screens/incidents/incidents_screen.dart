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
import '../map/rescue_route_screen.dart';

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
      backgroundColor: const Color(0xFF0B0D11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D11),
        title: Text('INCIDENT REGISTRY', style: AppTheme.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
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
            decoration: const BoxDecoration(
              color: Color(0xFF13151B),
              border: Border(bottom: BorderSide(color: Color(0xFF232733))),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: AppTheme.sans.copyWith(fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by location, sector, or emergency type...',
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
                                final priorityScore = inc.frp ?? 85.0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => RescueRouteScreen(incident: inc),
                                      ));
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF13151B),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: inc.severity == 'CRITICAL'
                                              ? AppColors.emergencyRed.withOpacity(0.4)
                                              : const Color(0xFF232733),
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
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.emergencyRed.withOpacity(0.18),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: AppColors.emergencyRed, width: 0.8),
                                                    ),
                                                    child: Text(
                                                      'PRIORITY ${priorityScore.toStringAsFixed(1)}',
                                                      style: AppTheme.mono.copyWith(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppColors.emergencyRed,
                                                      ),
                                                    ),
                                                  ),
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
                                                'COORDS: ${inc.latitude.toStringAsFixed(3)}° N, ${inc.longitude.toStringAsFixed(3)}° E',
                                                style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.infoCyan),
                                              ),
                                              Text(
                                                inc.source,
                                                style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted),
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
          color: selected ? AppColors.infoCyan.withOpacity(0.18) : const Color(0xFF0B0D11),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.infoCyan : const Color(0xFF232733)),
        ),
        child: Text(
          label,
          style: AppTheme.mono.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.infoCyan : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
