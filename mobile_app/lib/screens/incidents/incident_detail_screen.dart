import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/incident_model.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/status_chip.dart';

class IncidentDetailScreen extends StatefulWidget {
  final IncidentModel incident;

  const IncidentDetailScreen({super.key, required this.incident});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  late IncidentModel _inc;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _inc = widget.incident;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    final provider = context.read<IncidentProvider>();
    final ok = await provider.updateStatus(_inc.id, newStatus);
    if (mounted) {
      setState(() {
        _updating = false;
        if (ok) _inc = _inc.copyWith(status: newStatus);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to: $newStatus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBase,
      appBar: AppBar(
        title: Text('INCIDENT DOSSIER', style: AppTheme.mono.copyWith(fontSize: 14)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top Status Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCharcoal : AppColors.lightCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_inc.id, style: AppTheme.mono.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.infoCyan)),
                    Row(
                      children: [
                        StatusChip(label: _inc.severity),
                        const SizedBox(width: 6),
                        StatusChip(label: _inc.status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _inc.title,
                  style: AppTheme.sans.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      _inc.locationName,
                      style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Telemetry Specs
          Text('TELEMETRY & SENSOR PARAMETERS', style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCharcoal : AppColors.lightCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                _SpecRow(label: 'Ingestion Source', val: _inc.source),
                const Divider(height: 16),
                _SpecRow(label: 'Latitude', val: '${_inc.latitude} N'),
                const Divider(height: 16),
                _SpecRow(label: 'Longitude', val: '${_inc.longitude} E'),
                if (_inc.frp != null) ...[
                  const Divider(height: 16),
                  _SpecRow(
                    label: _inc.source.contains('SOS') || _inc.id.startsWith('SOS') ? 'Calculated Priority Score' : 'Fire Radiative Power (FRP)',
                    val: _inc.source.contains('SOS') || _inc.id.startsWith('SOS') ? '${_inc.frp!.toStringAsFixed(1)} / 100 (Dynamic Algorithm)' : '${_inc.frp} MW',
                  ),
                ],
                if (_inc.brightness != null) ...[
                  const Divider(height: 16),
                  _SpecRow(label: 'Brightness Temperature', val: '${_inc.brightness} K'),
                ],
                const Divider(height: 16),
                _SpecRow(label: 'Detection Timestamp', val: _inc.timestamp.toLocal().toString().split('.')[0]),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tactical Description
          Text('SITUATION SUMMARY', style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCharcoal : AppColors.lightCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Text(
              _inc.description,
              style: AppTheme.sans.copyWith(fontSize: 13, height: 1.45),
            ),
          ),

          const SizedBox(height: 24),

          // Operational Status Buttons
          Text('DISPATCH CONTROL', style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.truck, size: 16),
                  label: const Text('DISPATCH SQUAD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warningOrange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _updating ? null : () => _updateStatus('DISPATCHED'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.checkCircle, size: 16),
                  label: const Text('MARK RESOLVED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safeGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _updating ? null : () => _updateStatus('RESOLVED'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            icon: const Icon(LucideIcons.alertTriangle, size: 16),
            label: const Text('REVERT TO ACTIVE QUEUE'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: AppColors.emergencyRed,
            ),
            onPressed: _updating ? null : () => _updateStatus('ACTIVE'),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String val;

  const _SpecRow({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted)),
        Text(val, style: AppTheme.mono.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

