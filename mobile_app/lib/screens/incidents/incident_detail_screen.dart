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
        SnackBar(
          backgroundColor: AppColors.safeGreen,
          content: Text('Incident status updated to: $newStatus'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityScore = _inc.frp ?? 85.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D11),
        title: Text('INCIDENT DOSSIER', style: AppTheme.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top Status Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF13151B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF232733)),
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
                  style: AppTheme.sans.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textLight),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: AppColors.infoCyan),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _inc.locationName,
                        style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Operational Triage Specs
          Text(
            'TRIAGE PARAMETERS & TELEMETRY',
            style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF13151B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF232733)),
            ),
            child: Column(
              children: [
                _SpecRow(label: 'Ingestion Source', val: _inc.source),
                const Divider(color: Color(0xFF232733), height: 16),
                _SpecRow(label: 'Emergency Category', val: _inc.type),
                const Divider(color: Color(0xFF232733), height: 16),
                _SpecRow(
                  label: 'Triage Priority Score',
                  val: '${priorityScore.toStringAsFixed(1)} / 100 (${priorityScore >= 75 ? "CRITICAL" : "HIGH"})',
                  valColor: priorityScore >= 75 ? AppColors.emergencyRed : AppColors.warningOrange,
                ),
                const Divider(color: Color(0xFF232733), height: 16),
                _SpecRow(label: 'Target GPS Coordinates', val: '${_inc.latitude.toStringAsFixed(4)}° N, ${_inc.longitude.toStringAsFixed(4)}° E'),
                const Divider(color: Color(0xFF232733), height: 16),
                _SpecRow(label: 'Timestamp Logged', val: _inc.timestamp.toLocal().toString().split('.')[0]),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tactical Situation Summary
          Text(
            'FIELD SITUATION & CITIZEN REPORT',
            style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF13151B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF232733)),
            ),
            child: Text(
              _inc.description.isNotEmpty ? _inc.description : 'No additional tactical telemetry supplied.',
              style: AppTheme.sans.copyWith(fontSize: 13, height: 1.45, color: AppColors.textLight),
            ),
          ),

          const SizedBox(height: 20),

          // Action Bar: Dispatch / Update Status
          Text(
            'RESPONDER DISPATCH ACTIONS',
            style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.infoCyan,
                    foregroundColor: const Color(0xFF0B0D11),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(LucideIcons.truck, size: 16),
                  label: Text(
                    'DISPATCH SQUAD',
                    style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  onPressed: _updating ? null : () => _updateStatus('IN_PROGRESS'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safeGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(LucideIcons.checkCircle2, size: 16),
                  label: Text(
                    'MARK RESCUED',
                    style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  onPressed: _updating ? null : () => _updateStatus('RESOLVED'),
                ),
              ),
            ],
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
  final Color? valColor;

  const _SpecRow({required this.label, required this.val, this.valColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted)),
        Flexible(
          child: Text(
            val,
            style: AppTheme.mono.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valColor ?? AppColors.textLight,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
