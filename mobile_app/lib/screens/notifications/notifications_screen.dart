import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/network/websocket_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/alert_model.dart';
import '../../providers/alert_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/status_chip.dart';
import '../map/live_map_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedSeverity = 'ALL';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertProvider = context.watch<AlertProvider>();

    final filteredAlerts = alertProvider.alerts.where((a) {
      if (_selectedSeverity == 'ALL') return true;
      return a.severity.toUpperCase() == _selectedSeverity;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBase,
      appBar: AppBar(
        title: Text(
          'EMERGENCY BULLETINS',
          style: AppTheme.mono.copyWith(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        actions: [
          if (alertProvider.unreadCount > 0)
            IconButton(
              tooltip: 'Mark All Read',
              icon: const Icon(LucideIcons.checkCheck, size: 20),
              onPressed: () {
                alertProvider.markAllRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All alerts marked as acknowledged.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          if (alertProvider.alerts.isNotEmpty)
            IconButton(
              tooltip: 'Clear Bulletins',
              icon: const Icon(LucideIcons.trash2, size: 20),
              onPressed: () => _confirmClearAll(context, alertProvider),
            ),
        ],
      ),
      body: Column(
        children: [
          // WebSocket Connection Bar
          ValueListenableBuilder<WsConnectionState>(
            valueListenable: alertProvider.wsState,
            builder: (context, state, child) {
              Color color;
              String label;
              IconData icon;

              switch (state) {
                case WsConnectionState.connected:
                  color = AppColors.safeGreen;
                  label = 'FASTAPI WEBSOCKET /ws/alerts: CONNECTED (LIVE STREAM)';
                  icon = LucideIcons.radio;
                  break;
                case WsConnectionState.connecting:
                  color = AppColors.warningOrange;
                  label = 'CONNECTING TO /ws/alerts...';
                  icon = LucideIcons.loader;
                  break;
                case WsConnectionState.disconnected:
                  color = AppColors.emergencyRed;
                  label = 'WEBSOCKET DISCONNECTED (TAP TO RECONNECT)';
                  icon = LucideIcons.wifiOff;
                  break;
                case WsConnectionState.error:
                  color = AppColors.emergencyRed;
                  label = 'WEBSOCKET ERROR (TAP TO RETRY)';
                  icon = LucideIcons.alertTriangle;
                  break;
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: color.withOpacity(0.12),
                child: Row(
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTheme.mono.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    if (state == WsConnectionState.disconnected)
                      GestureDetector(
                        onTap: () => alertProvider.reconnectWs(),
                        child: Text(
                          'RETRY',
                          style: AppTheme.mono.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: color,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          // Severity Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('ALL', alertProvider.alerts.length),
                const SizedBox(width: 8),
                _buildFilterChip('CRITICAL', alertProvider.alerts.where((a) => a.severity == 'CRITICAL').length),
                const SizedBox(width: 8),
                _buildFilterChip('WARNING', alertProvider.alerts.where((a) => a.severity == 'WARNING').length),
                const SizedBox(width: 8),
                _buildFilterChip('INFO', alertProvider.alerts.where((a) => a.severity == 'INFO').length),
              ],
            ),
          ),

          const Divider(height: 1),

          // Alerts List
          Expanded(
            child: filteredAlerts.isEmpty
                ? EmptyStateView(
                    icon: LucideIcons.bellOff,
                    title: 'No Emergency Bulletins',
                    message: _selectedSeverity == 'ALL'
                        ? 'No active alerts broadcasted by command or telemetry sensors.'
                        : 'No bulletins currently matching $_selectedSeverity severity.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = filteredAlerts[index];
                      return _buildAlertCard(context, alert, isDark, alertProvider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedSeverity == label;
    return ChoiceChip(
      label: Text('$label ($count)', style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedSeverity = label);
        }
      },
      selectedColor: AppColors.emergencyRed.withOpacity(0.2),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: isSelected ? AppColors.emergencyRed : Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    AlertModel alert,
    bool isDark,
    AlertProvider provider,
  ) {
    Color severityColor;
    IconData icon;

    switch (alert.severity.toUpperCase()) {
      case 'CRITICAL':
        severityColor = AppColors.emergencyRed;
        icon = LucideIcons.shieldAlert;
        break;
      case 'WARNING':
        severityColor = AppColors.warningOrange;
        icon = LucideIcons.alertTriangle;
        break;
      default:
        severityColor = AppColors.infoCyan;
        icon = LucideIcons.info;
        break;
    }

    final formattedTime = DateFormat('HH:mm:ss • MMM dd').format(alert.timestamp);

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.emergencyRed,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 22),
      ),
      onDismissed: (_) {
        provider.dismissAlert(alert.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dismissed ${alert.id}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCharcoal : AppColors.lightCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: alert.severity == 'CRITICAL'
                ? AppColors.emergencyRed.withOpacity(0.4)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showAlertDetailsModal(context, alert),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: severityColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  alert.title,
                                  style: AppTheme.mono.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              StatusChip(label: alert.severity),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedTime,
                            style: AppTheme.sans.copyWith(
                              fontSize: 11,
                              color: isDark ? AppColors.textMuted : AppColors.textSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  alert.message,
                  style: AppTheme.sans.copyWith(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          alert.isLiveWebSocket ? LucideIcons.radio : LucideIcons.fileText,
                          size: 13,
                          color: alert.isLiveWebSocket ? AppColors.safeGreen : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          alert.isLiveWebSocket ? 'LIVE WEBSOCKET' : 'INTERNAL BULLETIN',
                          style: AppTheme.mono.copyWith(
                            fontSize: 10,
                            color: alert.isLiveWebSocket ? AppColors.safeGreen : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (alert.latitude != null && alert.longitude != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(LucideIcons.mapPin, size: 13, color: AppColors.infoCyan),
                        label: Text(
                          'MAP LOCATION',
                          style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.infoCyan, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LiveMapScreen(
                                focusCoordinateLat: alert.latitude,
                                focusCoordinateLng: alert.longitude,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAlertDetailsModal(BuildContext context, AlertModel alert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TACTICAL BULLETIN DETAILS',
                    style: AppTheme.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  StatusChip(label: alert.severity),
                ],
              ),
              const Divider(height: 24),
              Text(
                alert.title,
                style: AppTheme.mono.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Issued: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(alert.timestamp)}',
                style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: AppTheme.sans.copyWith(fontSize: 14, height: 1.5),
              ),
              if (alert.latitude != null && alert.longitude != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.crosshair, size: 16, color: AppColors.infoCyan),
                      const SizedBox(width: 8),
                      Text(
                        'Geo Target: ${alert.latitude!.toStringAsFixed(4)}, ${alert.longitude!.toStringAsFixed(4)}',
                        style: AppTheme.mono.copyWith(fontSize: 12, color: AppColors.infoCyan),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.infoCyan),
                    icon: const Icon(LucideIcons.map, size: 18, color: Colors.black),
                    label: Text(
                      'PINPOINT ON LIVE TACTICAL MAP',
                      style: AppTheme.mono.copyWith(fontWeight: FontWeight.w800, color: Colors.black),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveMapScreen(
                            focusCoordinateLat: alert.latitude,
                            focusCoordinateLng: alert.longitude,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context, AlertProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCharcoal,
        title: Text('Clear All Bulletins?', style: AppTheme.mono.copyWith(fontSize: 14)),
        content: Text(
          'This will remove all bulletins currently cached in the operational queue.',
          style: AppTheme.sans.copyWith(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
            onPressed: () {
              provider.clearAlerts();
              Navigator.pop(ctx);
            },
            child: const Text('CLEAR ALL'),
          ),
        ],
      ),
    );
  }
}

