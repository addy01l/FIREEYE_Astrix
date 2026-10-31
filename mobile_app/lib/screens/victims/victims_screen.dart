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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: isDark ? AppColors.darkCharcoal : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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

              Text('MEDICAL / CONDITION LOG', style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final victimProvider = context.watch<VictimProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBase,
      appBar: AppBar(
        title: Text('VICTIM TRIAGE DIRECTORY', style: AppTheme.mono.copyWith(fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => victimProvider.fetchVictims(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Privacy Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
            child: Row(
              children: [
                const Icon(LucideIcons.lock, size: 14, color: AppColors.infoCyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sensitive personal contact details are redacted pursuant to privacy protocols.',
                    style: AppTheme.sans.copyWith(fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: victimProvider.isLoading
                ? const LoadingView(message: 'FETCHING VICTIM REGISTRY...')
                : victimProvider.victims.isEmpty
                    ? EmptyStateView(
                        title: 'NO VICTIM RECORDS',
                        message: 'No active victim triage files on record.',
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
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.emergencyRed.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'PRIORITY #${v.priorityScore}',
                                              style: AppTheme.mono.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emergencyRed),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(v.id, style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.textMuted)),
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
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Condition: ${v.medicalCondition}', style: AppTheme.sans.copyWith(fontSize: 11)),
                                        Text('Infants: ${v.hasInfants ? "Yes" : "No"} | Elderly: ${v.hasElderly ? "Yes" : "No"}', style: AppTheme.mono.copyWith(fontSize: 9, color: AppColors.infoCyan)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Phone: ${v.contactNumber}', style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted)),
                                      TextButton.icon(
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

