import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/sos_service.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/status_chip.dart';
import '../mesh/mesh_status_screen.dart';
import '../sos/emergency_help_screen.dart';

class CitizenDashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const CitizenDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final SosService _sosService = SosService();

  List<Map<String, dynamic>> _mySosList = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadMySos();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadMySos() async {
    try {
      final list = await _sosService.getMySosRequests();
      if (mounted) {
        setState(() {
          _mySosList = list;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeSos = _mySosList.where((s) {
      final status = (s['status'] as String? ?? '').toUpperCase();
      return status != 'RESCUED' && status != 'CANCELLED';
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0D11) : AppColors.lightBase,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMySos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(user?.fullName ?? 'Citizen User'),
                const SizedBox(height: 16),
                _buildEmergencySosHero(),
                const SizedBox(height: 16),
                if (activeSos.isNotEmpty) ...[
                  _buildActiveSosCard(activeSos.first),
                  const SizedBox(height: 16),
                ],
                _buildQuickActionGrid(),
                const SizedBox(height: 16),
                _buildSafetyGuidelinesCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF232733)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const BrandLogo(size: 26, showTagline: false),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $name',
                    style: AppTheme.sans.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.safeGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.safeGreen, width: 0.8),
                        ),
                        child: Text(
                          'CIVILIAN USER',
                          style: AppTheme.mono.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.safeGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Citizen Defense Portal',
                        style: AppTheme.sans.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(LucideIcons.radio, size: 20, color: AppColors.safeGreen),
            tooltip: 'BLE Mesh Status',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshStatusScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySosHero() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A0D10), Color(0xFF190A0C), Color(0xFF13151B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emergencyRed.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            'IN IMMEDIATE DANGER?',
            style: AppTheme.mono.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: AppColors.emergencyRed,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Emergency Assistance Broadcast',
            style: AppTheme.sans.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Dispatches live GPS coordinates, medical vulnerabilities, and hazard telemetry directly to Incident Commanders and Field Responders.',
            style: AppTheme.sans.copyWith(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _pulseAnimation,
            child: SizedBox(
              width: 130,
              height: 130,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 12,
                  shadowColor: AppColors.emergencyRed.withOpacity(0.8),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmergencyHelpScreen()),
                  );
                  _loadMySos();
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertOctagon, size: 42, color: Colors.white),
                    const SizedBox(height: 4),
                    Text(
                      'SOS',
                      style: AppTheme.mono.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to begin automated multi-channel emergency broadcast (Works Offline via Bluetooth Mesh)',
            style: AppTheme.sans.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSosCard(Map<String, dynamic> sos) {
    final status = (sos['status'] as String? ?? 'PENDING').toUpperCase();
    final sosCode = sos['sos_code'] as String? ?? 'SOS-ACTIVE';
    final emergencyType = sos['emergency_type'] as String? ?? 'General Distress';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.emergencyRed, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.radio, size: 16, color: AppColors.emergencyRed),
                  const SizedBox(width: 8),
                  Text(
                    'ACTIVE SOS BEACON',
                    style: AppTheme.mono.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.emergencyRed,
                    ),
                  ),
                ],
              ),
              StatusChip(label: status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$sosCode • $emergencyType',
            style: AppTheme.mono.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Field rescue units are monitoring this beacon. Stay calm and keep device charged.',
            style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(LucideIcons.history, size: 14),
                label: const Text('View All SOS History'),
                onPressed: () => widget.onNavigateTab?.call(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EMERGENCY RESOURCES & ACTIONS',
          style: AppTheme.mono.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _buildActionTile(
              icon: LucideIcons.tent,
              title: 'Relief Shelters',
              subtitle: 'Beds, Food & Safe Camps',
              color: AppColors.safeGreen,
              onTap: () => widget.onNavigateTab?.call(3),
            ),
            _buildActionTile(
              icon: LucideIcons.map,
              title: 'Threat Map',
              subtitle: 'Active Disaster Zones',
              color: AppColors.infoCyan,
              onTap: () => widget.onNavigateTab?.call(1),
            ),
            _buildActionTile(
              icon: LucideIcons.history,
              title: 'My SOS Requests',
              subtitle: 'Track Rescue Status',
              color: AppColors.warningOrange,
              onTap: () => widget.onNavigateTab?.call(2),
            ),
            _buildActionTile(
              icon: LucideIcons.bluetooth,
              title: 'BLE Mesh Status',
              subtitle: 'Offline Peer Network',
              color: Colors.purpleAccent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshStatusScreen()));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF13151B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF232733)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.sans.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.sans.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyGuidelinesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF232733)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldAlert, size: 18, color: AppColors.infoCyan),
              const SizedBox(width: 8),
              Text(
                'DISASTER SURVIVAL PROTOCOLS',
                style: AppTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.infoCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGuidelineItem(
            '🌊 Flash Flood:',
            'Move immediately to higher ground. Avoid driving or wading through moving water.',
          ),
          const SizedBox(height: 8),
          _buildGuidelineItem(
            '🏚️ Structural Collapse / Earthquake:',
            'Drop, cover, and hold on. Keep away from exterior walls and high-voltage power lines.',
          ),
          const SizedBox(height: 8),
          _buildGuidelineItem(
            '🔥 Wildfire / Smoke Hazard:',
            'Stay low to avoid toxic smoke inhalation. Cover nose and mouth with a wet cloth.',
          ),
          const SizedBox(height: 8),
          _buildGuidelineItem(
            '📶 Zero Connectivity Mode:',
            'FIRE-EYE automatically broadcasts SOS beacons via Bluetooth Mesh to nearby citizens and rescue nodes.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
