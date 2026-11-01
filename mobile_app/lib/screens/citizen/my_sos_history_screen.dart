import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/sos_service.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_chip.dart';
import '../sos/emergency_help_screen.dart';

class MySosHistoryScreen extends StatefulWidget {
  const MySosHistoryScreen({super.key});

  @override
  State<MySosHistoryScreen> createState() => _MySosHistoryScreenState();
}

class _MySosHistoryScreenState extends State<MySosHistoryScreen> {
  final SosService _sosService = SosService();
  List<Map<String, dynamic>> _sosList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMySos();
  }

  Future<void> _fetchMySos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _sosService.getMySosRequests();
      if (mounted) {
        setState(() {
          _sosList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load SOS history: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0D11) : AppColors.lightBase,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
        elevation: 0,
        title: Text(
          'MY SOS REQUESTS',
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
            onPressed: _fetchMySos,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.emergencyRed,
        icon: const Icon(LucideIcons.alertTriangle, color: Colors.white, size: 18),
        label: Text(
          'NEW SOS',
          style: AppTheme.mono.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyHelpScreen()),
          );
          _fetchMySos();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Retrieving your SOS dispatch history...');
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        errorMessage: _errorMessage!,
        onRetry: _fetchMySos,
      );
    }

    if (_sosList.isEmpty) {
      return EmptyStateView(
        icon: LucideIcons.shieldCheck,
        title: 'No Emergency Requests',
        message: 'You have not submitted any active or archived SOS distress signals.',
        retryLabel: 'SUBMIT EMERGENCY SOS',
        onRetry: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyHelpScreen()),
          );
          _fetchMySos();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMySos,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _sosList.length,
        itemBuilder: (context, index) {
          final item = _sosList[index];
          return _buildSosCard(item);
        },
      ),
    );
  }

  Widget _buildSosCard(Map<String, dynamic> item) {
    final code = item['sos_code'] as String? ?? 'SOS-RECORD';
    final emergencyType = item['emergency_type'] as String? ?? 'General Distress';
    final severity = item['severity'] as String? ?? 'HIGH';
    final status = (item['status'] as String? ?? 'PENDING').toUpperCase();
    final notes = item['notes'] as String? ?? 'No extra notes provided';
    final createdAtRaw = item['created_at'] as String?;

    String formattedTime = 'Recently';
    if (createdAtRaw != null) {
      try {
        final dt = DateTime.parse(createdAtRaw).toLocal();
        formattedTime = DateFormat('MMM dd, yyyy • HH:mm').format(dt);
      } catch (_) {}
    }

    Color severityColor = AppColors.warningOrange;
    if (severity.toUpperCase() == 'CRITICAL') severityColor = AppColors.emergencyRed;
    if (severity.toUpperCase() == 'LOW') severityColor = AppColors.safeGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status == 'PENDING'
              ? AppColors.emergencyRed.withOpacity(0.6)
              : const Color(0xFF232733),
          width: status == 'PENDING' ? 1.4 : 1,
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
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: severityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    code,
                    style: AppTheme.mono.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              StatusChip(label: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            emergencyType,
            style: AppTheme.sans.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            notes,
            style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(color: Color(0xFF1E222D), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    formattedTime,
                    style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      severity.toUpperCase(),
                      style: AppTheme.mono.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: severityColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
