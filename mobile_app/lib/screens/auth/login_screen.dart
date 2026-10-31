import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_logo.dart';
import '../main_navigation_shell.dart';
import '../sos/emergency_help_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'commander');
  final _passwordController = TextEditingController(text: 'tactical123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showGatewayConfigModal() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCharcoal,
        title: Text('Configure FastAPI Gateway', style: AppTheme.mono.copyWith(fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify host address for running FastAPI backend:',
              style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: AppTheme.mono.copyWith(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:8000',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Emulator: http://10.0.2.2:8000\n• Windows/Desktop: http://127.0.0.1:8000\n• Physical Phone: http://<PC-LAN-IP>:8000',
              style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textSubtle),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    }
  }

  void _setPreset(String user, String pass) {
    setState(() {
      _usernameController.text = user;
      _passwordController.text = pass;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Bar with Gateway settings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BrandLogo(size: 32, showTagline: false),
                    InkWell(
                      onTap: _showGatewayConfigModal,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.darkCharcoal,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.server, size: 12, color: AppColors.infoCyan),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                ApiConfig.baseUrl.replaceFirst('https://', '').replaceFirst('http://', ''),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ==========================================
                // HERO: PUBLIC EMERGENCY HELP / SOS SECTION
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.emergencyRed.withOpacity(0.22),
                        AppColors.darkCharcoal,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.emergencyRed, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emergencyRed.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.emergencyRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.shieldAlert, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IN IMMEDIATE DANGER?',
                                  style: AppTheme.mono.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: AppColors.emergencyRed,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Instant SOS Dispatch • No Account Needed',
                                  style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Trapped under debris, encircled by fire, flash floods, or medical crisis? Broadcast high-precision GPS distress beacon directly to command & rescue squads.',
                        style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted, height: 1.35),
                      ),
                      const SizedBox(height: 16),

                      // REQUEST EMERGENCY HELP Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emergencyRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 6,
                          shadowColor: AppColors.emergencyRed.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(LucideIcons.radio, size: 20, color: Colors.white),
                        label: Text(
                          'REQUEST EMERGENCY HELP',
                          style: AppTheme.mono.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmergencyHelpScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.phone, size: 12, color: AppColors.infoCyan),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Emergency Hotlines: 112 (All) • 101 (Fire) • 108 (EMS)',
                              style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.infoCyan),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==========================================
                // DIVIDER: RESCUERS & OFFICIALS LOGIN
                // ==========================================
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.darkBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'RESCUERS & OFFICIALS LOGIN',
                        style: AppTheme.mono.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.darkBorder)),
                  ],
                ),

                const SizedBox(height: 18),

                // Rescuer & Officials Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Authorized Personnel Console',
                        style: AppTheme.sans.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Access tactical radar, satellite anomalies, and rescue dispatch.',
                        style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),

                      if (authProvider.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.emergencyRed.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.emergencyRed.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.alertCircle, color: AppColors.emergencyRed, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authProvider.errorMessage!,
                                  style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.emergencyRed),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      TextFormField(
                        controller: _usernameController,
                        style: AppTheme.mono.copyWith(fontSize: 13, color: AppColors.textLight),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter official username / callsign' : null,
                        decoration: const InputDecoration(
                          labelText: 'Official Callsign / Badge ID',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: 'e.g. commander, responder_01',
                          prefixIcon: Icon(LucideIcons.shield, size: 16, color: AppColors.textSubtle),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTheme.mono.copyWith(fontSize: 13, color: AppColors.textLight),
                        validator: (v) => v == null || v.length < 4 ? 'Enter valid security passcode' : null,
                        decoration: InputDecoration(
                          labelText: 'Security Passcode',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: 'Enter access token',
                          prefixIcon: const Icon(LucideIcons.lock, size: 16, color: AppColors.textSubtle),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 16,
                              color: AppColors.textSubtle,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.darkSurfaceElevated,
                          side: const BorderSide(color: AppColors.darkBorder),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.logIn, size: 16, color: AppColors.infoCyan),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SIGN IN TO COMMAND CONSOLE',
                                    style: AppTheme.mono.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 14),

                      // Quick Official Presets
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            'OFFICIAL DEMO PRESETS:',
                            style: AppTheme.mono.copyWith(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSubtle),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _PresetButton(label: 'Commander', onTap: () => _setPreset('commander', 'tactical123')),
                              _PresetButton(label: 'Responder', onTap: () => _setPreset('responder', 'tactical123')),
                              _PresetButton(label: 'Relief Team', onTap: () => _setPreset('volunteer', 'tactical123')),
                              _PresetButton(label: 'Citizen', onTap: () => _setPreset('citizen', 'tactical123')),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: TextButton.icon(
                          icon: const Icon(LucideIcons.userPlus, size: 14, color: AppColors.infoCyan),
                          label: Text(
                            'Register New Official / Volunteer',
                            style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.infoCyan, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceElevated,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Text(
          label,
          style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
