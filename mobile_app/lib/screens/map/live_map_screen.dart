import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/anomaly_model.dart';
import '../../models/incident_model.dart';
import '../../providers/anomaly_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/rescue_center_provider.dart';
import '../../providers/shelter_provider.dart';
import '../../widgets/status_chip.dart';
import '../incidents/incident_detail_screen.dart';

class LiveMapScreen extends StatefulWidget {
  final double? focusCoordinateLat;
  final double? focusCoordinateLng;

  const LiveMapScreen({
    super.key,
    this.focusCoordinateLat,
    this.focusCoordinateLng,
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();

  bool _showAnomalies = true;
  bool _showIncidents = true;
  bool _showShelters = true;
  bool _showRescueCenters = true;
  bool _locating = false;

  // Default coordinate center (Dehradun / Northern Sector operational area)
  late LatLng _initialCenter;

  @override
  void initState() {
    super.initState();
    if (widget.focusCoordinateLat != null && widget.focusCoordinateLng != null) {
      _initialCenter = LatLng(widget.focusCoordinateLat!, widget.focusCoordinateLng!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_initialCenter, 15.0);
      });
    } else {
      _initialCenter = const LatLng(30.3350, 78.0100);
    }
  }

  Future<void> _locateUser() async {
    setState(() => _locating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)),
        );
        _mapController.move(LatLng(pos.latitude, pos.longitude), 13.0);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. Map kept at regional center.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not obtain GPS fix: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showIncidentSheet(IncidentModel inc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCharcoal : AppColors.lightCard,
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
                Row(
                  children: [
                    StatusChip(label: inc.severity),
                    const SizedBox(width: 8),
                    StatusChip(label: inc.source, outlined: true),
                  ],
                ),
                StatusChip(label: inc.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              inc.title,
              style: AppTheme.sans.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              inc.locationName,
              style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              inc.description,
              style: AppTheme.sans.copyWith(fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CoordItem(label: 'LATITUDE', val: inc.latitude.toStringAsFixed(4)),
                  _CoordItem(label: 'LONGITUDE', val: inc.longitude.toStringAsFixed(4)),
                  if (inc.frp != null)
                    _CoordItem(label: 'FRP POWER', val: '${inc.frp} MW'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(LucideIcons.fileText, size: 16),
                label: const Text('OPEN FULL INCIDENT DOSSIER'),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => IncidentDetailScreen(incident: inc)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnomalySheet(AnomalyModel anom) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCharcoal : AppColors.lightCard,
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
                Row(
                  children: [
                    StatusChip(label: anom.isWildfire ? 'CRITICAL WILDFIRE' : 'THERMAL HOTSPOT'),
                    const SizedBox(width: 8),
                    const StatusChip(label: 'LIVE FASTAPI / NASA FIRMS', outlined: true),
                  ],
                ),
                Text(
                  '#${anom.id}',
                  style: AppTheme.mono.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              anom.isWildfire ? 'Satellite Confirmed Wildfire Detection' : 'Thermal Hotspot Sensor Trigger',
              style: AppTheme.mono.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Real-time anomaly ingestion via FastAPI Celery worker from NASA FIRMS VIIRS satellite pass.',
              style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CoordItem(label: 'LATITUDE', val: anom.latitude.toStringAsFixed(4)),
                  _CoordItem(label: 'LONGITUDE', val: anom.longitude.toStringAsFixed(4)),
                  _CoordItem(label: 'BRIGHTNESS', val: '${anom.brightness.toStringAsFixed(1)} K'),
                  _CoordItem(label: 'FRP POWER', val: '${anom.frp.toStringAsFixed(1)} MW'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: anom.isWildfire ? AppColors.emergencyRed : AppColors.warningOrange,
                ),
                icon: const Icon(LucideIcons.shieldAlert, size: 16, color: Colors.white),
                label: Text(
                  'DISPATCH RESCUE TEAM TO COORDINATES',
                  style: AppTheme.mono.copyWith(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dispatched alert to nearest rescue center for #${anom.id}'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final anomalyProvider = context.watch<AnomalyProvider>();
    final incidentProvider = context.watch<IncidentProvider>();
    final shelterProvider = context.watch<ShelterProvider>();
    final rescueProvider = context.watch<RescueCenterProvider>();

    final anomalies = anomalyProvider.anomalies;
    final incidents = incidentProvider.incidents;
    final shelters = shelterProvider.shelters;
    final rescueCenters = rescueProvider.centers;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBase,
      appBar: AppBar(
        title: Text('LIVE DISASTER MAP', style: AppTheme.mono.copyWith(fontSize: 14)),
        actions: [
          IconButton(
            icon: _locating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.infoCyan))
                : const Icon(LucideIcons.crosshair, size: 20),
            onPressed: _locating ? null : _locateUser,
            tooltip: 'Locate My Position',
          ),
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            onPressed: () => _mapController.move(_initialCenter, 12.0),
            tooltip: 'Reset Map View',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 12.0,
              minZoom: 4.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fireeye.app',
              ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // Thermal Anomalies (/api/anomalies/live)
                  if (_showAnomalies)
                    ...anomalies.map((anom) {
                      final color = anom.isWildfire ? AppColors.emergencyRed : AppColors.warningOrange;
                      return Marker(
                        point: LatLng(anom.latitude, anom.longitude),
                        width: 38,
                        height: 38,
                        child: GestureDetector(
                          onTap: () => _showAnomalySheet(anom),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.radio,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    }),

                  // Incident Markers
                  if (_showIncidents)
                    ...incidents.map((inc) {
                      final isCritical = inc.severity == 'CRITICAL';
                      final color = isCritical
                          ? AppColors.emergencyRed
                          : inc.severity == 'WARNING'
                              ? AppColors.warningOrange
                              : AppColors.infoCyan;

                      return Marker(
                        point: LatLng(inc.latitude, inc.longitude),
                        width: 42,
                        height: 42,
                        child: GestureDetector(
                          onTap: () => _showIncidentSheet(inc),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.55),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              inc.type.contains('Fire') ? LucideIcons.flame : LucideIcons.alertTriangle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }),

                  // Shelter Markers
                  if (_showShelters)
                    ...shelters.map((s) {
                      return Marker(
                        point: LatLng(s.latitude, s.longitude),
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.safeGreen,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(LucideIcons.tent, color: Colors.white, size: 18),
                        ),
                      );
                    }),

                  // Rescue Center Markers
                  if (_showRescueCenters)
                    ...rescueCenters.map((rc) {
                      return Marker(
                        point: LatLng(rc.latitude, rc.longitude),
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.infoBlue,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(LucideIcons.truck, color: Colors.white, size: 18),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),

          // Layer Toggle Controls (Top Pill)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkCharcoal : Colors.white).withOpacity(0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MapLayerPill(
                      label: 'Hotspots (${anomalies.length})',
                      active: _showAnomalies,
                      activeColor: AppColors.warningOrange,
                      icon: LucideIcons.radio,
                      onTap: () => setState(() => _showAnomalies = !_showAnomalies),
                    ),
                    const SizedBox(width: 8),
                    _MapLayerPill(
                      label: 'Incidents (${incidents.length})',
                      active: _showIncidents,
                      activeColor: AppColors.emergencyRed,
                      icon: LucideIcons.flame,
                      onTap: () => setState(() => _showIncidents = !_showIncidents),
                    ),
                    const SizedBox(width: 8),
                    _MapLayerPill(
                      label: 'Shelters (${shelters.length})',
                      active: _showShelters,
                      activeColor: AppColors.safeGreen,
                      icon: LucideIcons.tent,
                      onTap: () => setState(() => _showShelters = !_showShelters),
                    ),
                    const SizedBox(width: 8),
                    _MapLayerPill(
                      label: 'Rescue Posts (${rescueCenters.length})',
                      active: _showRescueCenters,
                      activeColor: AppColors.infoBlue,
                      icon: LucideIcons.truck,
                      onTap: () => setState(() => _showRescueCenters = !_showRescueCenters),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Map Legend (Bottom Left)
          Positioned(
            bottom: 16,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkCharcoal : Colors.white).withOpacity(0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('MAP LEGEND', style: AppTheme.mono.copyWith(fontSize: 9, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _LegendRow(color: AppColors.emergencyRed, label: 'Critical Fire / Anomaly'),
                  _LegendRow(color: AppColors.warningOrange, label: 'Disaster Warning / Slope'),
                  _LegendRow(color: AppColors.safeGreen, label: 'Designated Safe Shelter'),
                  _LegendRow(color: AppColors.infoBlue, label: 'Active Rescue Center Base'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordItem extends StatelessWidget {
  final String label;
  final String val;

  const _CoordItem({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTheme.mono.copyWith(fontSize: 8, color: AppColors.textMuted)),
        Text(val, style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MapLayerPill extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final IconData icon;
  final VoidCallback onTap;

  const _MapLayerPill({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? activeColor : AppColors.textSubtle.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: active ? activeColor : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.mono.copyWith(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? activeColor : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.sans.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

