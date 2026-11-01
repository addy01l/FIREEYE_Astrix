import 'admin/admin_users_screen.dart';
import 'citizen/citizen_navigation_shell.dart';
import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';

import '../core/theme/app_theme.dart';

import '../providers/alert_provider.dart';

import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../providers/victim_provider.dart';
import '../services/sos_service.dart';

import '../widgets/brand_logo.dart';

import 'auth/login_screen.dart';

import 'dashboard/dashboard_screen.dart';

import 'incidents/create_incident_screen.dart';

import 'incidents/incidents_screen.dart';

import 'map/live_map_screen.dart';

import 'notifications/notifications_screen.dart';

import 'profile/profile_screen.dart';

import 'dart:async';

import 'package:flutter/services.dart';

import '../services/mesh/mesh_manager.dart';

import 'mesh/mesh_status_screen.dart';

import 'rescue_centers/rescue_centers_screen.dart';

import 'shelters/shelters_screen.dart';

import 'victims/victims_screen.dart';



class MainNavigationShell extends StatefulWidget {

  final int initialIndex;



  const MainNavigationShell({super.key, this.initialIndex = 0});



  @override

  State<MainNavigationShell> createState() => _MainNavigationShellState();

}



class _MainNavigationShellState extends State<MainNavigationShell> {

  late int _currentIndex;

  StreamSubscription? _meshAlertSub;
  Timer? _syncTimer;



  @override

  void initState() {

    super.initState();

    _currentIndex = widget.initialIndex;

    _listenToMeshAlerts();

    _startOperationalSync();

  }

  void _startOperationalSync() {
    try {
      MeshManager.instance.startMesh();
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          context.read<IncidentProvider>().fetchIncidents();
          context.read<VictimProvider>().fetchVictims();
        } catch (_) {}
      }
    });

    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        try {
          context.read<IncidentProvider>().fetchIncidents();
          context.read<VictimProvider>().fetchVictims();
          MeshManager.instance.syncPendingPackets();
          SosService().syncOfflineQueue();
        } catch (_) {}
      }
    });
  }



  void _listenToMeshAlerts() {

    _meshAlertSub = MeshManager.instance.onSosAlertReceived.listen((packet) {

      if (mounted) {

        try { HapticFeedback.heavyImpact(); } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            backgroundColor: const Color(0xFFDC2626),

            duration: const Duration(seconds: 8),

            content: Row(

              children: [

                const Icon(LucideIcons.radio, color: Colors.white, size: 20),

                const SizedBox(width: 10),

                Expanded(

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text('🚨 OFFLINE BLE SOS RECEIVED!', style: AppTheme.mono.copyWith(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12)),

                      Text('Peer: ${packet.originDeviceId} • Stranded: ${packet.peopleCount} • Hop: ${packet.hopCount}', style: AppTheme.sans.copyWith(color: Colors.white70, fontSize: 11)),

                    ],

                  ),

                ),

              ],

            ),

            action: SnackBarAction(

              label: 'VIEW',

              textColor: Colors.white,

              onPressed: () {

                Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshStatusScreen()));

              },

            ),

          ),

        );

      }

    });

  }



  @override

  void dispose() {

    _meshAlertSub?.cancel();
    _syncTimer?.cancel();

    super.dispose();

  }



  void _onTabSelected(int index) {

    setState(() {

      _currentIndex = index;

    });

  }



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final alertProvider = context.watch<AlertProvider>();

    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated && !authProvider.isAdmin) {
      return const CitizenNavigationShell();
    }



    final screens = [

      DashboardScreen(onNavigateTab: _onTabSelected),

      const LiveMapScreen(),

      const IncidentsScreen(),

      const RescueCentersScreen(),

      const SheltersScreen(),

    ];



    return Scaffold(

      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBase,

      drawer: _buildTacticalDrawer(context, authProvider, alertProvider, isDark),

      body: IndexedStack(

        index: _currentIndex,

        children: screens,

      ),

      bottomNavigationBar: Container(

        decoration: BoxDecoration(

          border: Border(

            top: BorderSide(

              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,

              width: 1,

            ),

          ),

        ),

        child: NavigationBar(

          selectedIndex: _currentIndex,

          onDestinationSelected: _onTabSelected,

          backgroundColor: isDark ? AppColors.darkCharcoal : Colors.white,

          indicatorColor: AppColors.emergencyRed.withOpacity(0.18),

          destinations: const [

            NavigationDestination(

              icon: Icon(LucideIcons.layoutDashboard, size: 20),

              selectedIcon: Icon(LucideIcons.layoutDashboard, color: AppColors.emergencyRed, size: 20),

              label: 'Command',

            ),

            NavigationDestination(

              icon: Icon(LucideIcons.map, size: 20),

              selectedIcon: Icon(LucideIcons.map, color: AppColors.emergencyRed, size: 20),

              label: 'Live Map',

            ),

            NavigationDestination(

              icon: Icon(LucideIcons.flame, size: 20),

              selectedIcon: Icon(LucideIcons.flame, color: AppColors.emergencyRed, size: 20),

              label: 'Incidents',

            ),

            NavigationDestination(

              icon: Icon(LucideIcons.truck, size: 20),

              selectedIcon: Icon(LucideIcons.truck, color: AppColors.emergencyRed, size: 20),

              label: 'Rescue',

            ),

            NavigationDestination(

              icon: Icon(LucideIcons.tent, size: 20),

              selectedIcon: Icon(LucideIcons.tent, color: AppColors.emergencyRed, size: 20),

              label: 'Shelters',

            ),

          ],

        ),

      ),

      floatingActionButton: _currentIndex == 2 || _currentIndex == 0

          ? FloatingActionButton.extended(

              backgroundColor: AppColors.emergencyRed,

              icon: const Icon(LucideIcons.plus, color: Colors.white, size: 18),

              label: Text(

                'REPORT INCIDENT',

                style: AppTheme.mono.copyWith(

                  fontWeight: FontWeight.w800,

                  fontSize: 11,

                  letterSpacing: 0.8,

                  color: Colors.white,

                ),

              ),

              onPressed: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(builder: (_) => const CreateIncidentScreen()),

                );

              },

            )

          : null,

    );

  }



  Widget _buildTacticalDrawer(

    BuildContext context,

    AuthProvider authProvider,

    AlertProvider alertProvider,

    bool isDark,

  ) {

    final user = authProvider.currentUser;



    return Drawer(

      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBase,

      child: SafeArea(

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            // Drawer Header

            Container(

              padding: const EdgeInsets.all(20),

              color: isDark ? AppColors.darkCharcoal : Colors.grey.shade100,

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const BrandLogo(size: 32),

                  const SizedBox(height: 14),

                  Text(

                    user?.fullName ?? 'Tactical Officer',

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

                          color: AppColors.emergencyRed.withOpacity(0.15),

                          borderRadius: BorderRadius.circular(4),

                          border: Border.all(color: AppColors.emergencyRed, width: 0.8),

                        ),

                        child: Text(

                          user?.role.displayName.toUpperCase() ?? 'COMMANDER',

                          style: AppTheme.mono.copyWith(

                            fontSize: 10,

                            fontWeight: FontWeight.w700,

                            color: AppColors.emergencyRed,

                          ),

                        ),

                      ),

                      const SizedBox(width: 8),

                      Text(

                        user?.assignedStation ?? 'Dehradun Command',

                        style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),

                      ),

                    ],

                  ),

                ],

              ),

            ),



            const SizedBox(height: 12),



            // Navigation Options

            ListTile(

              leading: const Icon(LucideIcons.layoutDashboard, size: 20),

              title: Text('Command Dashboard', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),

              onTap: () {

                Navigator.pop(context);

                _onTabSelected(0);

              },

            ),

            ListTile(

              leading: const Icon(LucideIcons.map, size: 20),

              title: Text('Live Tactical Map', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),

              onTap: () {

                Navigator.pop(context);

                _onTabSelected(1);

              },

            ),

            ListTile(

              leading: const Icon(LucideIcons.flame, size: 20),

              title: Text('Incidents Register', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),

              onTap: () {

                Navigator.pop(context);

                _onTabSelected(2);

              },

            ),

            ListTile(

              leading: const Icon(LucideIcons.truck, size: 20),

              title: Text('Rescue Posts & Fleet', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),

              onTap: () {

                Navigator.pop(context);

                _onTabSelected(3);

              },

            ),

            ListTile(

              leading: const Icon(LucideIcons.tent, size: 20),

              title: Text('Emergency Shelters', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),

              onTap: () {

                Navigator.pop(context);

                _onTabSelected(4);

              },

            ),



            const Divider(),



            ListTile(
              leading: const Icon(LucideIcons.users, size: 20, color: AppColors.safeGreen),
              title: Text('User Management (RBAC)', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.safeGreen)),
              subtitle: Text('Manage Citizen & Official Roles', style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
              },
            ),

            // Auxiliary Operational Screens

            ListTile(

              leading: const Icon(LucideIcons.shieldAlert, size: 20, color: AppColors.emergencyRed),

              title: Text('Rescue Priority Queue', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.emergencyRed)),

              subtitle: Text('Civilian SOS Triage & Priority Scoring', style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted)),

              onTap: () {

                Navigator.pop(context);

                Navigator.push(context, MaterialPageRoute(builder: (_) => const VictimsScreen()));

              },

            ),

            ListTile(

              leading: const Icon(LucideIcons.radio, size: 20, color: AppColors.infoCyan),

              title: Text('Bluetooth Mesh Relay', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.infoCyan)),

              subtitle: Text('Offline Multi-Hop SOS Forwarding', style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted)),

              onTap: () {

                Navigator.pop(context);

                Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshStatusScreen()));

              },

            ),

            ListTile(

              leading: Badge(

                isLabelVisible: alertProvider.unreadCount > 0,

                label: Text('${alertProvider.unreadCount}'),

                backgroundColor: AppColors.emergencyRed,

                child: const Icon(LucideIcons.bell, size: 20, color: AppColors.warningOrange),

              ),

              title: Text('Emergency Bulletins', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),

              subtitle: Text('/ws/alerts & Notifications', style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted)),

              onTap: () {

                Navigator.pop(context);

                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));

              },

            ),

            ListTile(

              leading: const Icon(LucideIcons.shieldCheck, size: 20, color: AppColors.safeGreen),

              title: Text('Profile & Settings', style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),

              subtitle: Text('FastAPI Gateway & Role Switcher', style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted)),

              onTap: () {

                Navigator.pop(context);

                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));

              },

            ),



            const Spacer(),



            // Drawer Logout Action

            Container(

              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

              width: double.infinity,

              child: ElevatedButton.icon(

                style: ElevatedButton.styleFrom(

                  backgroundColor: AppColors.emergencyRed.withOpacity(0.12),

                  foregroundColor: AppColors.emergencyRed,

                  side: BorderSide(color: AppColors.emergencyRed.withOpacity(0.6)),

                  padding: const EdgeInsets.symmetric(vertical: 12),

                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

                ),

                icon: const Icon(LucideIcons.logOut, size: 16),

                label: Text(

                  'LOGOUT OFFICIAL CONSOLE',

                  style: AppTheme.mono.copyWith(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.8),

                ),

                onPressed: () {

                  Navigator.pop(context);

                  _confirmLogout(context, authProvider);

                },

              ),

            ),



            // Footer branding

            Padding(

              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),

              child: Text(

                'FIRE-EYE ASTRIX TACTICAL v1.0.0\nBLE Offline Mesh & PostGIS Integration',

                style: AppTheme.mono.copyWith(fontSize: 9, color: AppColors.textSubtle, height: 1.4),

              ),

            ),

          ],

        ),

      ),

    );

  }



  void _confirmLogout(BuildContext context, AuthProvider authProvider) {

    showDialog(

      context: context,

      builder: (ctx) => AlertDialog(

        backgroundColor: AppColors.darkCharcoal,

        title: Text('TERMINATE OFFICIAL SESSION?', style: AppTheme.mono.copyWith(fontSize: 14)),

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

              await authProvider.logout();

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

}

