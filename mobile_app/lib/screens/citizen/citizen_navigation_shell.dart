import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_logo.dart';
import '../auth/login_screen.dart';
import '../map/live_map_screen.dart';
import '../mesh/mesh_status_screen.dart';
import '../profile/profile_screen.dart';
import '../shelters/shelters_screen.dart';
import 'citizen_dashboard_screen.dart';
import 'my_sos_history_screen.dart';

class CitizenNavigationShell extends StatefulWidget {
  final int initialIndex;

  const CitizenNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<CitizenNavigationShell> createState() => _CitizenNavigationShellState();
}

class _CitizenNavigationShellState extends State<CitizenNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showEditProfileModal(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13151B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF232733)),
        ),
        title: Text(
          'UPDATE CITIZEN PROFILE',
          style: AppTheme.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: AppTheme.sans.copyWith(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(LucideIcons.user, size: 16),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                style: AppTheme.mono.copyWith(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Emergency Phone Number',
                  prefixIcon: Icon(LucideIcons.phone, size: 16),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter emergency contact' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.safeGreen),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await authProvider.updateProfile(
                  fullName: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Profile successfully updated' : 'Failed to update profile',
                      ),
                      backgroundColor: success ? AppColors.safeGreen : AppColors.emergencyRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();

    final screens = [
      CitizenDashboardScreen(onNavigateTab: _onTabSelected),
      const LiveMapScreen(),
      const MySosHistoryScreen(),
      const SheltersScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0D11) : AppColors.lightBase,
      drawer: _buildCitizenDrawer(context, authProvider, isDark),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E222D) : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          backgroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
          indicatorColor: AppColors.emergencyRed.withOpacity(0.18),
          destinations: const [
            NavigationDestination(
              icon: Icon(LucideIcons.home, size: 20),
              selectedIcon: Icon(LucideIcons.home, color: AppColors.emergencyRed, size: 20),
              label: 'Citizen Hub',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.map, size: 20),
              selectedIcon: Icon(LucideIcons.map, color: AppColors.emergencyRed, size: 20),
              label: 'Threat Map',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.history, size: 20),
              selectedIcon: Icon(LucideIcons.history, color: AppColors.emergencyRed, size: 20),
              label: 'My SOS',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.tent, size: 20),
              selectedIcon: Icon(LucideIcons.tent, color: AppColors.emergencyRed, size: 20),
              label: 'Shelters',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitizenDrawer(
    BuildContext context,
    AuthProvider authProvider,
    bool isDark,
  ) {
    final user = authProvider.currentUser;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0B0D11) : AppColors.lightBase,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF13151B),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(size: 30),
                  const SizedBox(height: 14),
                  Text(
                    user?.fullName ?? 'Citizen User',
                    style: AppTheme.mono.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.safeGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user?.email ?? '',
                          style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(LucideIcons.userCheck, size: 20, color: AppColors.safeGreen),
              title: Text('Edit Profile Details', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                _showEditProfileModal(context, authProvider);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.radio, size: 20, color: AppColors.infoCyan),
              title: Text('Offline BLE Mesh Network', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshStatusScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.tent, size: 20, color: AppColors.warningOrange),
              title: Text('Relief Shelters Directory', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                _onTabSelected(3);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.settings, size: 20),
              title: Text('Settings & Gateway', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            const Spacer(),
            const Divider(color: Color(0xFF232733)),
            ListTile(
              leading: const Icon(LucideIcons.logOut, size: 20, color: AppColors.emergencyRed),
              title: Text(
                'LOG OUT',
                style: AppTheme.mono.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emergencyRed,
                ),
              ),
              onTap: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
