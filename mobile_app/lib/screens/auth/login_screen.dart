import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/shelter_provider.dart';
import '../../providers/victim_provider.dart';
import '../../services/mesh/mesh_manager.dart';
import '../citizen/citizen_navigation_shell.dart';
import '../main_navigation_shell.dart';
import '../sos/emergency_help_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showOfficerSection = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showGatewayConfigModal() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13151B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF232733)),
        ),
        title: Text('Configure API Gateway', style: AppTheme.mono.copyWith(fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backend Gateway URL (Render / Local):',
              style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: AppTheme.mono.copyWith(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'https://fireeye-astrix-backend.onrender.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.safeGreen),
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ApiClient.instance.updateBaseUrl(newUrl);
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('API Gateway updated: $newUrl')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      try {
        context.read<IncidentProvider>().fetchIncidents();
        context.read<VictimProvider>().fetchVictims();
        MeshManager.instance.startMesh();
      } catch (_) {}
      if (authProvider.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CitizenNavigationShell()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      body: SafeArea(
        child: Column(
          children: [
            // Clean Top Bar matching reference screenshot
            _buildTopBar(),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 720;
                    if (isWide) {
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: _buildCitizenHeroCard()),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _buildSafetyStatusCard(),
                                    const SizedBox(height: 16),
                                    _buildNearestShelterCard(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildOfficerSection(authProvider),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCitizenHeroCard(),
                          const SizedBox(height: 16),
                          _buildSafetyStatusCard(),
                          const SizedBox(height: 16),
                          _buildNearestShelterCard(),
                          const SizedBox(height: 20),
                          _buildOfficerSection(authProvider),
                          const SizedBox(height: 24),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top Bar matching reference image
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0D11),
        border: Border(bottom: BorderSide(color: Color(0xFF1E222D), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Fire-Eye',
                style: AppTheme.sans.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          Row(
            children: [
              // Connected Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF102A18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1B4D2B), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'System Connected',
                      style: AppTheme.sans.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Server config icon
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'API Gateway Config',
                icon: const Icon(LucideIcons.settings2, size: 16, color: AppColors.textMuted),
                onPressed: _showGatewayConfigModal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Left Hero Card: Need Emergency Help? + Massive Circular Red SOS Button
  Widget _buildCitizenHeroCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232733), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sub-header for test compatibility
          Text(
            'IN IMMEDIATE DANGER?',
            style: AppTheme.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppColors.emergencyRed,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Need Emergency Help?',
            style: AppTheme.sans.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Press and hold the button below to alert rescue teams.',
            style: AppTheme.sans.copyWith(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Giant Circular Red SOS Button
          ScaleTransition(
            scale: _pulseAnimation,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyHelpScreen()),
                );
              },
              child: Container(
                width: 175,
                height: 175,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.4),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'SOS',
                    style: AppTheme.sans.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // REQUEST EMERGENCY HELP Button (satisfies test and provides 1-tap navigation)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(LucideIcons.radio, size: 18, color: Colors.white),
              label: Text(
                'REQUEST EMERGENCY HELP',
                style: AppTheme.mono.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyHelpScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Right Top Card: "SAFETY STATUS" matching reference screenshot
  Widget _buildSafetyStatusCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232733), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAFETY STATUS',
            style: AppTheme.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'High Risk',
            style: AppTheme.sans.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Landslide warnings active in your region.',
            style: AppTheme.sans.copyWith(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 14),

          // Inner bullet box from screenshot
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0D11),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E222D)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletItem('Heavy rainfall expected'),
                const SizedBox(height: 6),
                _buildBulletItem('Avoid steep slopes'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Row(
      children: [
        const Text('• ', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        Expanded(
          child: Text(
            text,
            style: AppTheme.sans.copyWith(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  // Right Bottom Card: "NEAREST SHELTER" matching reference screenshot
  Widget _buildNearestShelterCard() {
    ShelterProvider? shelterProvider;
    try {
      shelterProvider = Provider.of<ShelterProvider>(context, listen: false);
    } catch (_) {}
    final shelters = shelterProvider?.shelters ?? [];
    final nearest = shelters.isNotEmpty ? shelters.first : null;

    final name = nearest?.name ?? 'Shelter data unavailable';
    final distance = 'Distance requires a live GPS route';
    final capacity = nearest?.capacity;
    final available = nearest?.availableBeds;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232733), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEAREST SHELTER',
            style: AppTheme.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: AppTheme.sans.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            distance,
            style: AppTheme.sans.copyWith(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),

          // Capacity & Available grid from screenshot
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0D11),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E222D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Capacity', style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(capacity?.toString() ?? '—', style: AppTheme.mono.copyWith(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textLight)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0D11),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E222D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available', style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        available?.toString() ?? '—',
                        style: AppTheme.mono.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Officer / Rescuer Login Accordion & Form
  Widget _buildOfficerSection(AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232733)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header toggle
          InkWell(
            onTap: () => setState(() => _showOfficerSection = !_showOfficerSection),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.infoCyan.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.shieldCheck, size: 18, color: AppColors.infoCyan),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RESCUERS & OFFICIALS LOGIN',
                                style: AppTheme.mono.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Command Console • Tactical Dispatch • Rescue Units',
                                style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _showOfficerSection ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Form body
          if (_showOfficerSection) ...[
            const Divider(color: Color(0xFF232733), height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      style: AppTheme.mono.copyWith(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Email or Username',
                        hintText: 'aditya@astrix.com or admin',
                        prefixIcon: Icon(LucideIcons.user, size: 16),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter email or username' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: AppTheme.mono.copyWith(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Passcode / Security Token',
                        prefixIcon: const Icon(LucideIcons.lock, size: 16),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 16),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter passcode' : null,
                    ),
                    const SizedBox(height: 18),

                    if (authProvider.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.emergencyRed.withOpacity(0.3)),
                        ),
                        child: Text(
                          authProvider.errorMessage!,
                          style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.emergencyRed),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.infoCyan,
                        foregroundColor: const Color(0xFF0B0D11),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      child: authProvider.isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(
                              'SIGN IN TO COMMAND CONSOLE',
                              style: AppTheme.mono.copyWith(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}
