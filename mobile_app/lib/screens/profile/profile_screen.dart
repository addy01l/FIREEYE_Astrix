import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/anomaly_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/shelter_provider.dart';
import '../../widgets/status_chip.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPingingBackend = false;

  void _showGatewayModal(BuildContext context) {
    final controller = TextEditingController(text: ApiConfig.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCharcoal,
        title: Text(
          'CONFIGURE FASTAPI GATEWAY',
          style: AppTheme.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select or enter the host address running the FIRE-EYE FastAPI server (uvicorn app.main:app):',
              style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: AppTheme.mono.copyWith(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'FastAPI Base URL',
                hintText: 'http://10.0.2.2:8000',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.cloud, size: 14, color: AppColors.emergencyRed),
                  label: const Text('Render Cloud Live'),
                  onPressed: () => controller.text = 'https://fireeye-astrix-backend.onrender.com',
                ),
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.smartphone, size: 14),
                  label: const Text('Android (10.0.2.2)'),
                  onPressed: () => controller.text = 'http://10.0.2.2:8000',
                ),
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.monitor, size: 14),
                  label: const Text('Desktop (127.0.0.1)'),
                  onPressed: () => controller.text = 'http://127.0.0.1:8000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ApiConfig.setBaseUrl(newUrl);
                ApiClient.instance.updateBaseUrl(newUrl);
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('API Gateway updated to $newUrl'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('APPLY GATEWAY'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final anomalyProvider = context.watch<AnomalyProvider>();
    final incidentProvider = context.watch<IncidentProvider>();
    final shelterProvider = context.watch<ShelterProvider>();

    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBase,
      appBar: AppBar(
        title: Text(
          'TACTICAL PROFILE & SETTINGS',
          style: AppTheme.mono.copyWith(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCharcoal : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.emergencyRed, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        (user?.username.isNotEmpty == true)
                            ? user!.username.substring(0, 1).toUpperCase()
                            : 'C',
                        style: AppTheme.mono.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.emergencyRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                user?.fullName ?? 'Tactical Officer',
                                style: AppTheme.mono.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusChip(label: user?.role.name.toUpperCase() ?? 'COMMANDER'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Callsign: @${user?.username ?? 'commander'}',
                          style: AppTheme.mono.copyWith(
                            fontSize: 12,
                            color: isDark ? AppColors.textMuted : AppColors.textSubtle,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Station: ${user?.assignedStation ?? 'Dehradun Command Center'}',
                          style: AppTheme.sans.copyWith(
                            fontSize: 12,
                            color: AppColors.infoCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // FastAPI Server Config Card
            Text(
              'FASTAPI BACKEND GATEWAY',
              style: AppTheme.mono.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark ? AppColors.textMuted : AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCharcoal : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
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
                          Icon(
                            LucideIcons.server,
                            size: 16,
                            color: anomalyProvider.isBackendOnline ? AppColors.safeGreen : AppColors.warningOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            anomalyProvider.isBackendOnline ? 'SERVER ONLINE' : 'SERVER OFFLINE / FALLBACK',
                            style: AppTheme.mono.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: anomalyProvider.isBackendOnline ? AppColors.safeGreen : AppColors.warningOrange,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: _isPingingBackend
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(LucideIcons.refreshCw, size: 14),
                        label: Text(
                          'PING',
                          style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _isPingingBackend ? null : _pingBackend,
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Text(
                    'REST Base URL:',
                    style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ApiConfig.baseUrl,
                    style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.infoCyan),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'WebSocket Endpoint:',
                    style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ApiConfig.wsAlertsUrl,
                    style: AppTheme.mono.copyWith(fontSize: 12, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.settings2, size: 16),
                      label: Text(
                        'SWITCH SERVER ADDRESS / IP',
                        style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _showGatewayModal(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Diagnostics and Counts
            Text(
              'TELEMETRY & CACHED DATA',
              style: AppTheme.mono.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark ? AppColors.textMuted : AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCharcoal : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  _buildDiagnosticRow(
                    'Thermal Hotspots (/api/anomalies/live)',
                    '${anomalyProvider.anomalies.length}',
                    anomalyProvider.isBackendOnline ? AppColors.safeGreen : AppColors.warningOrange,
                  ),
                  const Divider(height: 16),
                  _buildDiagnosticRow(
                    'Operational Incidents',
                    '${incidentProvider.incidents.length}',
                    AppColors.infoCyan,
                  ),
                  const Divider(height: 16),
                  _buildDiagnosticRow(
                    'Registered Shelters',
                    '${shelterProvider.shelters.length}',
                    AppColors.safeGreen,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: Text(
                  'LOGOUT TACTICAL SESSION',
                  style: AppTheme.mono.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                onPressed: () => _confirmLogout(context, authProvider),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                'FIRE-EYE Emergency Response System v1.0.0\nASTRIX Tactical Operations Platform',
                textAlign: TextAlign.center,
                style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textSubtle, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.sans.copyWith(fontSize: 12)),
        Text(
          value,
          style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCharcoal,
        title: Text('Terminate Session?', style: AppTheme.mono.copyWith(fontSize: 14)),
        content: Text(
          'Your tactical authentication token will be cleared from secure hardware storage.',
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
              await authProvider.logout();
              if (mounted) {
                Navigator.of(this.context).pushAndRemoveUntil(
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

  Future<void> _pingBackend() async {
    setState(() => _isPingingBackend = true);
    final anomalyProvider = context.read<AnomalyProvider>();
    await anomalyProvider.checkHealthAndFetch();
    if (!mounted) return;
    setState(() => _isPingingBackend = false);

    final isOnline = anomalyProvider.isBackendOnline;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isOnline ? AppColors.safeGreen : AppColors.warningOrange,
        content: Text(
          isOnline
              ? 'Backend Reachable! Received ${anomalyProvider.anomalies.length} thermal anomalies.'
              : 'Could not reach FastAPI server at ${ApiConfig.baseUrl}. Is uvicorn running?',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

