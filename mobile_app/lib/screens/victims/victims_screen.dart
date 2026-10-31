import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/victim_model.dart';
import '../../providers/victim_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_chip.dart';

class VictimsScreen extends StatelessWidget {
  const VictimsScreen({super.key});

  void _showTriageActionModal(BuildContext context, VictimModel victim) {
    String status = victim.status;
    final notesController = TextEditingController(text: victim.medicalCondition);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF13151B),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: const Color(0xFF232733)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('UPDATE TRIAGE RECORD', style: AppTheme.mono.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${victim.id} • ${victim.fullName}', style: AppTheme.sans.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
              Text('Location: ${victim.location}', style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 14),

              Text('TRIAGE / RESCUE STATUS', style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('TRAPPED'),
                    selected: status == 'TRAPPED',
                    onSelected: (val) => setModalState(() => status = 'TRAPPED'),
                  ),
                  ChoiceChip(
                    label: const Text('IN TRANSIT'),
                    selected: status == 'IN TRANSIT',
                    onSelected: (val) => setModalState(() => status = 'IN TRANSIT'),
                  ),
                  ChoiceChip(
                    label: const Text('MEDICAL CARE'),
                    selected: status == 'MEDICAL CARE',
                    onSelected: (val) => setModalState(() => status = 'MEDICAL CARE'),
                  ),
                  ChoiceChip(
                    label: const Text('RESCUED'),
                    selected: status == 'RESCUED',
                    onSelected: (val) => setModalState(() => status = 'RESCUED'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text('CONDITION / RESCUE LOG', style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: notesController,
                style: AppTheme.sans.copyWith(fontSize: 12),
                decoration: const InputDecoration(hintText: 'Enter victim condition update...'),
              ),
              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: () async {
                  await context.read<VictimProvider>().updateStatus(
                        victim.id,
                        status,
                        notes: notesController.text.trim(),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  backgroundColor: AppColors.emergencyRed,
                ),
                child: const Text('CONFIRM TRIAGE RECORD UPDATE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final victimProvider = context.watch<VictimProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D11),
        title: Text('RESCUE TRIAGE QUEUE', style: AppTheme.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => victimProvider.fetchVictims(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Operational Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF13151B),
            child: Row(
              children: [
                const Icon(LucideIcons.listOrdered, size: 14, color: AppColors.infoCyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SOS requests dynamically prioritized by vulnerability, severity, risk zone, and isolation index.',
                    style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: victimProvider.isLoading
                ? const LoadingView(message: 'FETCHING TRIAGE QUEUE...')
                : victimProvider.victims.isEmpty
                    ? EmptyStateView(
                        title: 'NO ACTIVE SOS CASES',
                        message: 'All victim requests have been attended to or evacuated.',
                        onRetry: () => victimProvider.fetchVictims(),
                      )
                    : RefreshIndicator(
                        onRefresh: () => victimProvider.fetchVictims(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: victimProvider.victims.length,
                          itemBuilder: (context, idx) {
                            final v = victimProvider.victims[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF13151B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF232733)),
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
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.emergencyRed.withOpacity(0.18),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: AppColors.emergencyRed, width: 0.8),
                                            ),
                                            child: Text(
                                              '#${idx + 1} PRIORITY: ${v.priorityScore}',
                                              style: AppTheme.mono.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emergencyRed),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(v.id, style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.infoCyan)),
                                        ],
                                      ),
                                      StatusChip(label: v.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    v.fullName,
                                    style: AppTheme.sans.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    v.location,
                                    style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0B0D11),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF1E222D)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text('Condition: ${v.medicalCondition}', style: AppTheme.sans.copyWith(fontSize: 11)),
                                        ),
                                        Text('Infants: ${v.hasInfants ? "Yes" : "No"} | Elderly: ${v.hasElderly ? "Yes" : "No"}',
                                            style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.infoCyan)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Contact: ${v.contactNumber}', style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted)),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                        icon: const Icon(LucideIcons.edit2, size: 12),
                                        label: const Text('UPDATE TRIAGE'),
                                        onPressed: () => _showTriageActionModal(context, v),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
