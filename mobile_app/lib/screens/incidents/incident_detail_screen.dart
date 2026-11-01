import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
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
  bool _loadingAi = true;
  Map<String, dynamic>? _aiAnalysis;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    _inc = widget.incident;
    _fetchAiAnalysis();
  }

  Future<void> _fetchAiAnalysis() async {
    setState(() {
      _loadingAi = true;
      _aiError = null;
    });
    try {
      final res = await ApiClient.instance.get('/api/v1/sos/${_inc.id}/ai-analysis');
      Map<String, dynamic>? data;
      if (res.data is Map<String, dynamic>) {
        data = res.data as Map<String, dynamic>;
      } else if (res.data is String) {
        try {
          final decoded = jsonDecode(res.data as String);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (_) {}
      }

      if (res.statusCode == 200 && data != null) {
        if (mounted) {
          setState(() {
            _aiAnalysis = data;
            _loadingAi = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _aiError = 'Tactical analysis currently unavailable.';
            _loadingAi = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiError = 'Offline or AI service unreachable.';
          _loadingAi = false;
        });
      }
    }
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

          const SizedBox(height: 16),

          // AI SOS RESPONSE ASSISTANT (GROQ LLM)
          _buildGroqAIAssistantSection(),

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

  Widget _buildGroqAIAssistantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.bot, size: 16, color: AppColors.infoCyan),
                const SizedBox(width: 6),
                Text(
                  'AI SOS RESPONSE ASSISTANT',
                  style: AppTheme.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.infoCyan,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.infoCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.infoCyan.withValues(alpha: 0.4)),
              ),
              child: Text(
                'GROQ LLM',
                style: AppTheme.mono.copyWith(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.infoCyan),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF13151B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.infoCyan.withValues(alpha: 0.3)),
          ),
          child: _loadingAi
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.infoCyan),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Synthesizing tactical AI rescue intelligence...',
                          style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              : _aiError != null
                  ? Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 18, color: AppColors.warningOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _aiError!,
                            style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                        TextButton(
                          onPressed: _fetchAiAnalysis,
                          child: Text(
                            'RETRY',
                            style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.infoCyan, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )
                  : _buildAnalysisContent(),
        ),
      ],
    );
  }

  Widget _buildAnalysisContent() {
    final summary = _aiAnalysis?['incident_summary']?.toString() ?? 'Tactical review in progress.';
    final urgency = (_aiAnalysis?['suggested_urgency_level']?.toString() ?? _inc.severity).toUpperCase();
    final modelUsed = _aiAnalysis?['model_used']?.toString() ?? 'groq-openai/gpt-oss-120b';

    final riskList = (_aiAnalysis?['identified_risk_factors'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final actionsList = (_aiAnalysis?['recommended_rescue_actions'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final resourcesList = (_aiAnalysis?['required_rescue_resources'] as List?)?.map((e) => e.toString()).toList() ?? [];

    final isCritical = urgency == 'CRITICAL';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Urgency Level Header
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCritical ? LucideIcons.flame : LucideIcons.alertTriangle,
                  size: 14,
                  color: isCritical ? AppColors.emergencyRed : AppColors.warningOrange,
                ),
                const SizedBox(width: 6),
                Text(
                  'SUGGESTED URGENCY: $urgency',
                  style: AppTheme.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isCritical ? AppColors.emergencyRed : AppColors.warningOrange,
                  ),
                ),
              ],
            ),
            Text(
              modelUsed,
              style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textSubtle),
            ),
          ],
        ),

        const Divider(color: Color(0xFF232733), height: 20),

        // Incident Summary
        Text(
          'INCIDENT SUMMARY',
          style: AppTheme.mono.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0D11),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF232733)),
          ),
          child: Text(
            summary,
            style: AppTheme.sans.copyWith(fontSize: 12.5, height: 1.4, color: AppColors.textLight),
          ),
        ),

        const SizedBox(height: 14),

        // Identified Risk Factors
        if (riskList.isNotEmpty) ...[
          Text(
            'IDENTIFIED RISK FACTORS',
            style: AppTheme.mono.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warningOrange),
          ),
          const SizedBox(height: 6),
          ...riskList.map((risk) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(LucideIcons.alertTriangle, size: 12, color: AppColors.warningOrange),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        risk,
                        style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textLight),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
        ],

        // Recommended Tactical Rescue Actions
        if (actionsList.isNotEmpty) ...[
          Text(
            'RECOMMENDED RESCUE ACTIONS',
            style: AppTheme.mono.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.infoCyan),
          ),
          const SizedBox(height: 6),
          ...actionsList.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final action = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.infoCyan.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$idx',
                      style: AppTheme.mono.copyWith(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.infoCyan),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action,
                      style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textLight),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
        ],

        // Required Rescue Resources
        if (resourcesList.isNotEmpty) ...[
          Text(
            'REQUIRED RESCUE RESOURCES',
            style: AppTheme.mono.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.safeGreen),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: resourcesList.map((res) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF232733)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.packageCheck, size: 12, color: AppColors.safeGreen),
                    const SizedBox(width: 6),
                    Text(
                      res,
                      style: AppTheme.mono.copyWith(fontSize: 10.5, color: AppColors.textLight),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
        ],

        // Advisory Note
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF232733)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.shieldAlert, size: 13, color: AppColors.textSubtle),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Advisory only — review and confirm tactical actions prior to dispatch.',
                  style: AppTheme.sans.copyWith(fontSize: 10, color: AppColors.textSubtle, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ],
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


