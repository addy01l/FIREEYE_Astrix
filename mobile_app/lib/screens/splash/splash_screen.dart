import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_logo.dart';
import '../auth/login_screen.dart';
import '../citizen/citizen_navigation_shell.dart';
import '../main_navigation_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
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
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandLogo(size: 54, showTagline: false),
            const SizedBox(height: 14),
            Text(
              AppConstants.appName,
              style: AppTheme.mono.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppConstants.appTagline,
              style: AppTheme.sans.copyWith(
                fontSize: 12,
                color: AppColors.infoCyan,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.emergencyRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
