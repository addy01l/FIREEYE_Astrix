import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'citizen';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ApiClient.instance.post(
        ApiConfig.registerEndpoint,
        data: {
          'full_name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': _role,
          'password': _passwordController.text.trim(),
        },
      );
      if (mounted) {
        setState(() => _isLoading = false);
        _showResult(true, 'Registration successful! You may now sign in.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Backend register endpoint is currently pending on FastAPI
        _showResult(
          false,
          'Backend registration endpoint (/api/v1/auth/register) is not active on server. You can sign in immediately using preset callsigns.',
        );
      }
    }
  }

  void _showResult(bool success, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCharcoal,
        title: Row(
          children: [
            Icon(
              success ? LucideIcons.checkCircle2 : LucideIcons.info,
              color: success ? AppColors.safeGreen : AppColors.warningOrange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(success ? 'Registration Success' : 'Backend Note', style: AppTheme.mono.copyWith(fontSize: 14)),
          ],
        ),
        content: Text(message, style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textLight)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (success) Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: Text('NEW REGISTRATION', style: AppTheme.mono.copyWith(fontSize: 14)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CIVILIAN & VOLUNTEER ENROLLMENT',
                  style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
                Text(
                  'Join the FIRE-EYE emergency intelligence network.',
                  style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  style: AppTheme.sans.copyWith(fontSize: 13),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
                  decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(LucideIcons.user, size: 16)),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _usernameController,
                  style: AppTheme.mono.copyWith(fontSize: 13),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter username' : null,
                  decoration: const InputDecoration(hintText: 'Username / Callsign', prefixIcon: Icon(LucideIcons.atSign, size: 16)),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTheme.sans.copyWith(fontSize: 13),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                  decoration: const InputDecoration(hintText: 'Email Address', prefixIcon: Icon(LucideIcons.mail, size: 16)),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTheme.mono.copyWith(fontSize: 13),
                  validator: (v) => v == null || v.length < 8 ? 'Enter phone number' : null,
                  decoration: const InputDecoration(hintText: 'Phone Number', prefixIcon: Icon(LucideIcons.phone, size: 16)),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _role,
                  dropdownColor: AppColors.darkSurfaceElevated,
                  decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.shield, size: 16)),
                  items: const [
                    DropdownMenuItem(value: 'citizen', child: Text('Civilian Citizen')),
                    DropdownMenuItem(value: 'volunteer', child: Text('Relief Volunteer')),
                    DropdownMenuItem(value: 'responder', child: Text('Field Responder')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _role = val);
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: AppTheme.mono.copyWith(fontSize: 13),
                  validator: (v) => v == null || v.length < 6 ? 'Password must be min 6 characters' : null,
                  decoration: const InputDecoration(hintText: 'Password', prefixIcon: Icon(LucideIcons.lock, size: 16)),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('SUBMIT REGISTRATION'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

