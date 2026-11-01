import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/models/user_model.dart';
import 'package:mobile_app/providers/alert_provider.dart';
import 'package:mobile_app/providers/anomaly_provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/incident_provider.dart';
import 'package:mobile_app/providers/mesh_provider.dart';
import 'package:mobile_app/providers/rescue_center_provider.dart';
import 'package:mobile_app/providers/shelter_provider.dart';
import 'package:mobile_app/providers/victim_provider.dart';
import 'package:mobile_app/screens/admin/admin_users_screen.dart';
import 'package:mobile_app/screens/citizen/citizen_dashboard_screen.dart';
import 'package:mobile_app/screens/citizen/citizen_navigation_shell.dart';
import 'package:mobile_app/screens/main_navigation_shell.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  UserModel? _mockUser;

  void setMockUser(UserModel? user) {
    _mockUser = user;
    notifyListeners();
  }

  @override
  UserModel? get currentUser => _mockUser;

  @override
  bool get isAuthenticated => _mockUser != null;

  @override
  bool get isAdmin => _mockUser?.role.isAdmin ?? false;

  @override
  bool get isCitizen => _mockUser?.role.isCitizen ?? true;

  @override
  UserRole get currentRole => _mockUser?.role ?? UserRole.citizen;

  @override
  String? get errorMessage => null;

  @override
  bool get isLoading => false;

  @override
  Future<bool> login(String username, String password) async => true;

  @override
  Future<void> logout() async {
    _mockUser = null;
    notifyListeners();
  }

  @override
  Future<void> restoreSession() async {}

  @override
  Future<bool> updateProfile({String? fullName, String? phone}) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FIRE-EYE Role-Based Access Control (RBAC) - Model & Role Unit Tests', () {
    test('Role resolution maps admin, commander, and rescue to isAdmin=true', () {
      final adminRole = UserRole.fromString('admin');
      final commanderRole = UserRole.fromString('commander');
      final rescueRole = UserRole.fromString('rescue');

      expect(adminRole.isAdmin, isTrue);
      expect(adminRole.isCitizen, isFalse);
      expect(commanderRole.isAdmin, isTrue);
      expect(rescueRole.isAdmin, isTrue);
    });

    test('Role resolution maps user, citizen, and null to isCitizen=true and isAdmin=false', () {
      final userRole = UserRole.fromString('user');
      final citizenRole = UserRole.fromString('citizen');
      final defaultRole = UserRole.fromString(null);

      expect(userRole.isAdmin, isFalse);
      expect(userRole.isCitizen, isTrue);
      expect(citizenRole.isAdmin, isFalse);
      expect(citizenRole.isCitizen, isTrue);
      expect(defaultRole.isAdmin, isFalse);
      expect(defaultRole.isCitizen, isTrue);
    });

    test('UserModel correctly parses roles and preserves access tokens', () {
      final adminJson = {
        'id': '7900f312-14ea-49d0-9e1b-626228307084',
        'username': 'aditya@astrix.com',
        'email': 'aditya@astrix.com',
        'full_name': 'Aditya Admin',
        'role': 'admin',
        'access_token': 'test_admin_jwt',
      };
      final admin = UserModel.fromJson(adminJson);
      expect(admin.role.isAdmin, isTrue);
      expect(admin.role.isCitizen, isFalse);
      expect(admin.token, equals('test_admin_jwt'));

      final citizenJson = {
        'id': '38289592-1f93-498e-a862-5587b765da2e',
        'username': 'jhaaditya474@gmail.com',
        'email': 'jhaaditya474@gmail.com',
        'full_name': 'Aditya Citizen',
        'role': 'user',
        'access_token': 'test_user_jwt',
      };
      final citizen = UserModel.fromJson(citizenJson);
      expect(citizen.role.isAdmin, isFalse);
      expect(citizen.role.isCitizen, isTrue);
    });
  });

  group('FIRE-EYE UI Role Guard & Navigation Tests', () {
    late MockAuthProvider mockAuth;

    setUp(() {
      mockAuth = MockAuthProvider();
    });

    testWidgets('Citizen entering MainNavigationShell is redirected to CitizenNavigationShell', (tester) async {
      final citizenUser = UserModel(
        id: '38289592-1f93-498e-a862-5587b765da2e',
        username: 'jhaaditya474@gmail.com',
        email: 'jhaaditya474@gmail.com',
        fullName: 'Aditya Civilian',
        role: UserRole.citizen,
      );
      mockAuth.setMockUser(citizenUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
            ChangeNotifierProvider<AnomalyProvider>(create: (_) => AnomalyProvider()),
            ChangeNotifierProvider<IncidentProvider>(create: (_) => IncidentProvider()),
            ChangeNotifierProvider<ShelterProvider>(create: (_) => ShelterProvider()),
            ChangeNotifierProvider<RescueCenterProvider>(create: (_) => RescueCenterProvider()),
            ChangeNotifierProvider<VictimProvider>(create: (_) => VictimProvider()),
            ChangeNotifierProvider<AlertProvider>(create: (_) => AlertProvider()),
            ChangeNotifierProvider<MeshProvider>(create: (_) => MeshProvider()),
          ],
          child: const MaterialApp(
            home: MainNavigationShell(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CitizenNavigationShell), findsOneWidget);
      expect(find.text('Citizen Hub'), findsOneWidget);
      expect(find.text('My SOS'), findsOneWidget);
    });

    testWidgets('CitizenDashboardScreen renders SOS Emergency Broadcast and safety protocols', (tester) async {
      final citizenUser = UserModel(
        id: '38289592-1f93-498e-a862-5587b765da2e',
        username: 'jhaaditya474@gmail.com',
        email: 'jhaaditya474@gmail.com',
        fullName: 'Aditya Civilian',
        role: UserRole.citizen,
      );
      mockAuth.setMockUser(citizenUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
          ],
          child: const MaterialApp(
            home: CitizenDashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Welcome, Aditya Civilian'), findsOneWidget);
      expect(find.text('CIVILIAN USER'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
      expect(find.text('Relief Shelters'), findsOneWidget);
      expect(find.text('Threat Map'), findsOneWidget);
      expect(find.text('DISASTER SURVIVAL PROTOCOLS'), findsOneWidget);
    });

    testWidgets('AdminUsersScreen blocks access with 403 Forbidden when viewed by a citizen', (tester) async {
      final citizenUser = UserModel(
        id: '38289592-1f93-498e-a862-5587b765da2e',
        username: 'jhaaditya474@gmail.com',
        email: 'jhaaditya474@gmail.com',
        fullName: 'Aditya Civilian',
        role: UserRole.citizen,
      );
      mockAuth.setMockUser(citizenUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
          ],
          child: const MaterialApp(
            home: AdminUsersScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('403 FORBIDDEN'), findsOneWidget);
      expect(find.text('Only authorized Incident Commanders and Administrators can view and manage user accounts.'), findsOneWidget);
    });
  });
}
