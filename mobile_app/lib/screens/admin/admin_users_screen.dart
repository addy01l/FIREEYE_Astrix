import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_chip.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(() {
      setState(() {
        _filterText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _userService.listUsers();
      if (mounted) {
        setState(() {
          _users = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load users: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmRoleChange(Map<String, dynamic> user) async {
    final messenger = ScaffoldMessenger.of(context);
    final currentRole = (user['role'] as String? ?? 'user').toLowerCase();
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    final username = user['username'] ?? 'User';
    final userId = user['id']?.toString() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13151B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF232733)),
        ),
        title: Text(
          'CONFIRM ROLE CHANGE',
          style: AppTheme.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to change the role of @$username from "${currentRole.toUpperCase()}" to "${newRole.toUpperCase()}"?\n\nThis will immediately modify their administrative privileges in the database.',
          style: AppTheme.sans.copyWith(fontSize: 13, color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newRole == 'admin' ? AppColors.emergencyRed : AppColors.safeGreen,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Change to ${newRole.toUpperCase()}'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _userService.updateUserRole(userId, newRole);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Successfully updated @$username to role ${newRole.toUpperCase()}'),
            backgroundColor: AppColors.safeGreen,
          ),
        );
        _fetchUsers();
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update role: $e'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final messenger = ScaffoldMessenger.of(context);
    final currentStatus = user['is_active'] as bool? ?? true;
    final newStatus = !currentStatus;
    final username = user['username'] ?? 'User';
    final userId = user['id']?.toString() ?? '';

    try {
      await _userService.updateUserStatus(userId, newStatus);
      messenger.showSnackBar(
        SnackBar(
          content: Text('@$username is now ${newStatus ? "ACTIVE" : "INACTIVE"}'),
          backgroundColor: newStatus ? AppColors.safeGreen : AppColors.warningOrange,
        ),
      );
      _fetchUsers();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Status update failed: $e'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Strict Authorization check
    if (!authProvider.isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0D11),
        appBar: AppBar(
          title: const Text('UNAUTHORIZED ACCESS'),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.shieldAlert, size: 48, color: AppColors.emergencyRed),
                const SizedBox(height: 16),
                Text(
                  '403 FORBIDDEN',
                  style: AppTheme.mono.copyWith(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.emergencyRed),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only authorized Incident Commanders and Administrators can view and manage user accounts.',
                  textAlign: TextAlign.center,
                  style: AppTheme.sans.copyWith(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredUsers = _users.where((u) {
      if (_filterText.isEmpty) return true;
      final uname = (u['username'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      final name = (u['full_name'] as String? ?? '').toLowerCase();
      return uname.contains(_filterText) || email.contains(_filterText) || name.contains(_filterText);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0D11) : AppColors.lightBase,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
        elevation: 0,
        title: Text(
          'USER MANAGEMENT (RBAC)',
          style: AppTheme.mono.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Refresh',
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: AppTheme.mono.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by username, email or name...',
                prefixIcon: const Icon(LucideIcons.search, size: 16),
                suffixIcon: _filterText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF13151B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF232733)),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildUserList(filteredUsers),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users) {
    if (_isLoading) {
      return const LoadingView(message: 'Loading registered accounts...');
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        errorMessage: _errorMessage!,
        onRetry: _fetchUsers,
      );
    }

    if (users.isEmpty) {
      return const EmptyStateView(
        icon: LucideIcons.users,
        title: 'No Users Found',
        message: 'No registered accounts match your current filter criteria.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final username = user['username'] as String? ?? 'user';
    final fullName = user['full_name'] as String? ?? username;
    final email = user['email'] as String? ?? 'No email';
    final role = (user['role'] as String? ?? 'user').toUpperCase();
    final isActive = user['is_active'] as bool? ?? true;
    final isAdmin = role == 'ADMIN' || role == 'COMMANDER';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAdmin ? AppColors.emergencyRed.withOpacity(0.4) : const Color(0xFF232733),
          width: isAdmin ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isAdmin ? AppColors.emergencyRed.withOpacity(0.2) : AppColors.safeGreen.withOpacity(0.2),
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: AppTheme.mono.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isAdmin ? AppColors.emergencyRed : AppColors.safeGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: AppTheme.sans.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '@$username',
                        style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  StatusChip(label: role),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isActive ? AppColors.safeGreen : AppColors.emergencyRed).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : 'INACTIVE',
                      style: AppTheme.mono.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isActive ? AppColors.safeGreen : AppColors.emergencyRed,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(LucideIcons.mail, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  email,
                  style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF1E222D), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: isActive ? AppColors.emergencyRed.withOpacity(0.5) : AppColors.safeGreen),
                ),
                icon: Icon(isActive ? LucideIcons.userX : LucideIcons.userCheck, size: 14),
                label: Text(
                  isActive ? 'Deactivate' : 'Activate',
                  style: AppTheme.mono.copyWith(fontSize: 11),
                ),
                onPressed: () => _toggleUserStatus(user),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: isAdmin ? const Color(0xFF232733) : AppColors.emergencyRed,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(isAdmin ? LucideIcons.shieldOff : LucideIcons.shieldCheck, size: 14),
                label: Text(
                  isAdmin ? 'Demote to User' : 'Promote to Admin',
                  style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w800),
                ),
                onPressed: () => _confirmRoleChange(user),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
