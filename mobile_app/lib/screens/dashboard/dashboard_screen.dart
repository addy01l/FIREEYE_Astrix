import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/alert_provider.dart';
import '../../providers/anomaly_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/rescue_center_provider.dart';
import '../../providers/shelter_provider.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/stat_kpi_card.dart';
import '../../widgets/status_chip.dart';
import '../auth/login_screen.dart';
import '../incidents/incident_detail_screen.dart';
import '../victims/victims_screen.dart';
import '../mesh/mesh_status_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13151B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF232733)),
        ),
        title: Text('LOGOUT OFFICIAL SESSION?', style: AppTheme.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
        content: Text(
          'Do you want to log out of the official command console and return to the emergency landing page?',
          style: AppTheme.sans.copyWith(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anomalyProvider = context.watch<AnomalyProvider>();
    final incidentProvider = context.watch<IncidentProvider>();
    final shelterProvider = context.watch<ShelterProvider>();
    final rescueProvider = context.watch<RescueCenterProvider>();
    final alertProvider = context.watch<AlertProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D11),
        elevation: 0,
        title: const BrandLogo(size: 24),
        actions: [
          // System Status Chip
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF102A18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1B4D2B), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'SYSTEM ONLINE',
                  style: AppTheme.mono.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),

          // Logout Action
          IconButton(
            tooltip: 'Logout Official Session',
            icon: const Icon(LucideIcons.logOut, size: 18, color: AppColors.emergencyRed),
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            anomalyProvider.checkHealthAndFetch(),
            incidentProvider.fetchIncidents(),
            shelterProvider.fetchShelters(),
            rescueProvider.fetchRescueCenters(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Clean Operational Headline
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF13151B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF232733)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.activity, color: AppColors.emergencyRed, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INCIDENT COMMAND RADAR',
                          style: AppTheme.mono.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppColors.emergencyRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${incidentProvider.activeCount} active SOS dispatches • ${anomalyProvider.anomalies.length} hazard hotspots monitored',
                          style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // BLE Offline Mesh Relay Operational Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF13151B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF232733)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.radio, size: 16, color: AppColors.infoCyan),
                      const SizedBox(width: 8),
                      Text(
                        'BLE OFFLINE MESH RELAY',
                        style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textLight),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(LucideIcons.arrowUpRight, size: 12, color: AppColors.infoCyan),
                    label: Text(
                      'MESH STATUS',
                      style: AppTheme.mono.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.infoCyan),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshStatusScreen()));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Operational KPI Grid (Clean metrics)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                StatKpiCard(
                  icon: LucideIcons.alertOctagon,
                  label: 'Active SOS Calls',
                  value: '${incidentProvider.activeCount}',
                  subtext: '${incidentProvider.criticalCount} Critical Priority',
                  tone: incidentProvider.criticalCount > 0 ? KpiTone.critical : KpiTone.neutral,
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
                StatKpiCard(
                  icon: LucideIcons.flame,
                  label: 'Hazard Zones',
                  value: '${anomalyProvider.anomalies.length}',
                  subtext: 'Active Threat Sectors',
                  tone: KpiTone.info,
                  onTap: () => widget.onNavigateTab?.call(1),
                ),
                StatKpiCard(
                  icon: LucideIcons.tent,
                  label: 'Shelter Capacity',
                  value: '${shelterProvider.totalAvailable}',
                  subtext: 'Beds Available in Relief Camps',
                  tone: KpiTone.safe,
                  onTap: () => widget.onNavigateTab?.call(4),
                ),
                StatKpiCard(
                  icon: LucideIcons.truck,
                  label: 'Rescue Fleet',
                  value: '${rescueProvider.totalVehicles}',
                  subtext: '${rescueProvider.totalPersonnel} Responders on Duty',
                  tone: KpiTone.warning,
                  onTap: () => widget.onNavigateTab?.call(3),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Live Alert Marquee
            if (alertProvider.alerts.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CRITICAL EMERGENCY BULLETINS',
                    style: AppTheme.mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.textMuted,
                    ),
                  ),
                  StatusChip(
                    label: '${alertProvider.alerts.length} ALERTS',
                    color: AppColors.emergencyRed,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...alertProvider.alerts.take(2).map((a) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13151B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF232733)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (a.severity == 'CRITICAL' ? AppColors.emergencyRed : AppColors.warningOrange).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          LucideIcons.radio,
                          size: 16,
                          color: a.severity == 'CRITICAL' ? AppColors.emergencyRed : AppColors.warningOrange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    a.title,
                                    style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                StatusChip(label: a.severity),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              a.message,
                              style: AppTheme.sans.copyWith(
                                fontSize: 11,
                                color: AppColors.textLight,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),
            ],

            // Active SOS Queue Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ACTIVE SOS QUEUE',
                    style: AppTheme.mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(LucideIcons.listOrdered, size: 13, color: AppColors.infoCyan),
                  label: Text('TRIAGE QUEUE', style: AppTheme.mono.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.infoCyan)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VictimsScreen()));
                  },
                ),
                const SizedBox(width: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => widget.onNavigateTab?.call(2),
                  child: Text('ALL', style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Active SOS Cards with priority scores
            ...incidentProvider.incidents.take(4).map((inc) {
              final priorityScore = inc.frp ?? 85.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => IncidentDetailScreen(incident: inc)),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13151B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: inc.severity == 'CRITICAL' ? AppColors.emergencyRed.withOpacity(0.4) : const Color(0xFF232733),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: inc.severity == 'CRITICAL'
                                ? AppColors.emergencyRed.withOpacity(0.15)
                                : AppColors.warningOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            inc.type.contains('Fire') ? LucideIcons.flame : LucideIcons.alertTriangle,
                            size: 18,
                            color: inc.severity == 'CRITICAL' ? AppColors.emergencyRed : AppColors.warningOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      inc.title,
                                      style: AppTheme.sans.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: priorityScore >= 75 ? AppColors.emergencyRed.withOpacity(0.18) : AppColors.warningOrange.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: priorityScore >= 75 ? AppColors.emergencyRed : AppColors.warningOrange, width: 0.8),
                                    ),
                                    child: Text(
                                      'PRIORITY ${priorityScore.toStringAsFixed(1)}',
                                      style: AppTheme.mono.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: priorityScore >= 75 ? AppColors.emergencyRed : AppColors.warningOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                inc.locationName,
                                style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  StatusChip(label: inc.status),
                                  Text(
                                    '${inc.latitude.toStringAsFixed(4)}° N, ${inc.longitude.toStringAsFixed(4)}° E',
                                    style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.infoCyan),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
