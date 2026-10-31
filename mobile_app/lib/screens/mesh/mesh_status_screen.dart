import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/mesh_provider.dart';
import '../../services/mesh/mesh_packet_model.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/status_chip.dart';

class MeshStatusScreen extends StatefulWidget {
  const MeshStatusScreen({super.key});

  @override
  State<MeshStatusScreen> createState() => _MeshStatusScreenState();
}

class _MeshStatusScreenState extends State<MeshStatusScreen> {
  void _triggerSimulatedPacket(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13151B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF232733)),
        ),
        title: Text('SIMULATE BLE RELAY HOP', style: AppTheme.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
        content: Text(
          'This simulates receiving an offline SOS packet from nearby device "FE-NODE-ALPHA", testing multi-hop validation, TTL decrement, hop trail append, and store-and-forward relay.',
          style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<MeshProvider>().testSimulateMultiHopRelay(
                    testOriginId: 'FE-NODE-ALPHA',
                    emergencyType: 'Trapped / Structural Collapse',
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.safeGreen,
                    content: Text('Simulated BLE packet received and relayed successfully!'),
                  ),
                );
              }
            },
            child: const Text('INJECT PACKET'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggle(BuildContext context) async {
    final meshProvider = context.read<MeshProvider>();
    final isRunning = meshProvider.isMeshRunning;
    if (isRunning) {
      await meshProvider.toggleMesh();
    } else {
      final success = await meshProvider.toggleMesh();
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1E222D),
            content: Text(
              '⚠️ Unable to start BLE Mesh Radio. Ensure Bluetooth is enabled on device and "Nearby Devices" permission is granted.',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meshProvider = context.watch<MeshProvider>();
    final peers = meshProvider.nearbyPeers;
    final records = meshProvider.packetRecords;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D11),
        elevation: 0,
        title: Text(
          'BLUETOOTH MESH RELAY',
          style: AppTheme.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            tooltip: 'Force Cloud Sync',
            icon: meshProvider.isSyncing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.infoCyan))
                : const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.infoCyan),
            onPressed: meshProvider.isSyncing ? null : () => meshProvider.syncNow(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => meshProvider.syncNow(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Mesh Node Identity & Radio Switch
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF13151B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: meshProvider.isMeshRunning ? const Color(0xFF1B4D2B) : const Color(0xFF232733),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (meshProvider.isMeshRunning ? AppColors.safeGreen : AppColors.textMuted).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                LucideIcons.radio,
                                size: 20,
                                color: meshProvider.isMeshRunning ? AppColors.safeGreen : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meshProvider.deviceId,
                                    style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textLight),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    meshProvider.isMeshRunning ? 'Central Scanner + GATT Server Active' : 'Mesh Radio Standby',
                                    style: AppTheme.sans.copyWith(fontSize: 11, color: meshProvider.isMeshRunning ? AppColors.safeGreen : AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: meshProvider.isMeshRunning,
                        activeColor: AppColors.safeGreen,
                        onChanged: (_) => _handleToggle(context),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF232733), height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Last Cloud Sync: ${meshProvider.lastSyncTime != null ? DateFormat('HH:mm:ss').format(meshProvider.lastSyncTime!) : 'Awaiting Connection'}',
                          style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Protocol: ${MeshPacketModel.currentProtocolVersion}',
                        style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.infoCyan, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4-Card Operational Metric Counters
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _buildStatTile('Pending SOS', '${meshProvider.pendingCount}', 'Local Awaiting Relay', AppColors.warningOrange, LucideIcons.clock),
                _buildStatTile('Received Packets', '${meshProvider.receivedCount}', 'From Neighbor Relays', AppColors.infoCyan, LucideIcons.arrowDownLeft),
                _buildStatTile('Relayed Multi-Hop', '${meshProvider.relayedCount}', 'Forwarded to Peers', AppColors.infoBlue, LucideIcons.share2),
                _buildStatTile('Cloud Uploaded', '${meshProvider.uploadedCount}', 'Delivered to Backend', AppColors.safeGreen, LucideIcons.cloudUpload),
              ],
            ),

            const SizedBox(height: 20),

            // Nearby BLE Relays Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NEARBY BLE RELAY PEERS (${peers.length})',
                  style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.textMuted),
                ),
                Text(
                  'Auto-Discovery',
                  style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.safeGreen, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (peers.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF13151B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF232733)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.bluetoothSearching, size: 18, color: AppColors.infoCyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        meshProvider.isMeshRunning
                            ? 'Listening for nearby FIRE-EYE BLE mesh beacons in radius...'
                            : 'Mesh radio is paused. Turn on switch above to discover peers.',
                        style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...peers.map((p) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13151B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF232733)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.bluetooth, color: AppColors.infoCyan, size: 16),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: AppTheme.mono.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textLight)),
                              Text('MAC: ${p.address}', style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0D11),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF1E222D)),
                        ),
                        child: Text(
                          '${p.rssi} dBm',
                          style: AppTheme.mono.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: p.rssi > -70 ? AppColors.safeGreen : AppColors.warningOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 20),

            // Store-and-Forward Packet Queue
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'STORE-AND-FORWARD PACKET QUEUE (${records.length})',
                    style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                  icon: const Icon(LucideIcons.playCircle, size: 12, color: AppColors.emergencyRed),
                  label: Text('TEST RELAY', style: AppTheme.mono.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emergencyRed)),
                  onPressed: () => _triggerSimulatedPacket(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (records.isEmpty) ...[
              EmptyStateView(
                title: 'MESH QUEUE IS EMPTY',
                message: 'No active SOS packets in transit. Generate an offline SOS to initiate store-and-forward relay.',
                onRetry: () => meshProvider.syncNow(),
              ),
            ] else ...[
              ...records.map((r) {
                final p = r.packet;
                final stateColor = _getStateColor(r.state);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13151B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: r.state == MeshPacketState.uploaded ? const Color(0xFF1B4D2B) : const Color(0xFF232733),
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: stateColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: stateColor, width: 0.8),
                                ),
                                child: Text(
                                  r.state.name.toUpperCase(),
                                  style: AppTheme.mono.copyWith(fontSize: 9, fontWeight: FontWeight.w900, color: stateColor),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                p.packetId.length > 8 ? p.packetId.substring(0, 8) : p.packetId,
                                style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.infoCyan, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          StatusChip(label: p.severity),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.notes,
                        style: AppTheme.sans.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 6),
                      // Multi-hop routing trail
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0D11),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF1E222D)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Hop Count: ${p.hopCount}', style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.textMuted)),
                                Text('TTL Remaining: ${p.ttl}', style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.warningOrange, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Trail: ${p.hops.join(" ➔ ")}',
                              style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.infoCyan),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (r.associatedSosCode != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Backend Code: ${r.associatedSosCode}',
                          style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.safeGreen, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }



  Widget _buildStatTile(String label, String value, String subtext, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF232733)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Text(value, style: AppTheme.mono.copyWith(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(subtext, style: AppTheme.sans.copyWith(fontSize: 9, color: AppColors.textSubtle), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }



  Color _getStateColor(MeshPacketState state) {
    switch (state) {
      case MeshPacketState.pending:
        return AppColors.warningOrange;
      case MeshPacketState.received:
        return AppColors.infoCyan;
      case MeshPacketState.relayed:
        return AppColors.infoBlue;
      case MeshPacketState.uploaded:
      case MeshPacketState.acknowledged:
        return AppColors.safeGreen;
      case MeshPacketState.failed:
        return AppColors.emergencyRed;
    }
  }
}
