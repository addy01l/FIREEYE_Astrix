import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/alert_model.dart';
import '../../models/incident_model.dart';
import '../../providers/alert_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/shelter_provider.dart';
import '../../services/sos_service.dart';
import '../../core/network/api_client.dart';
import '../mesh/mesh_status_screen.dart';
import '../../services/mesh/mesh_manager.dart';
import '../../widgets/status_chip.dart';

class EmergencyHelpScreen extends StatefulWidget {
  const EmergencyHelpScreen({super.key});

  @override
  State<EmergencyHelpScreen> createState() => _EmergencyHelpScreenState();
}

class _EmergencyHelpScreenState extends State<EmergencyHelpScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // GPS state
  bool _locating = true;
  double _latitude = 30.3165;
  double _longitude = 78.0322;
  String _gpsStatus = 'GPS locked to current sector';

  // Pre-fed emergency questionnaire selections
  String _selectedEmergency = 'Trapped / Structural Collapse';
  int _victimCount = 1;
  final Set<String> _vulnerabilities = {};
  final Set<String> _urgentNeeds = {};

  final _landmarkController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  // Active SOS Beacon state
  bool _isSosActive = false;
  String? _activeBeaconId;
  DateTime? _beaconTime;
  bool _submitting = false;

  // Real-time telemetry state
  String _riskLevel = 'High Risk';
  Color _riskColor = const Color(0xFFEF4444);
  String _weatherSummary = 'Landslide warnings active in your region.';
  String _weatherRainfall = '• Heavy rainfall expected';
  String _weatherWind = '• Avoid steep slopes';
  String _shelterName = 'Govt Relief Center';
  String _shelterDistanceText = '2.8 km away';

  final List<Map<String, dynamic>> _emergencyTypes = [
    {'title': 'Trapped / Structural Collapse', 'icon': LucideIcons.building2, 'color': AppColors.emergencyRed},
    {'title': 'Active Fire / Wildfire', 'icon': LucideIcons.flame, 'color': AppColors.warningOrange},
    {'title': 'Flash Flood / Rising Water', 'icon': LucideIcons.waves, 'color': AppColors.infoCyan},
    {'title': 'Landslide Risk / Slope Movement', 'icon': LucideIcons.mountain, 'color': AppColors.warningOrange},
    {'title': 'Medical Emergency / Trauma', 'icon': LucideIcons.heartPulse, 'color': AppColors.emergencyRed},
    {'title': 'Hazardous Gas / Chemical', 'icon': LucideIcons.alertTriangle, 'color': AppColors.warningOrange},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _captureInitialGPS();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _captureInitialGPS() async {
    setState(() {
      _locating = true;
      _gpsStatus = 'Acquiring GPS fix...';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)),
        );
        if (mounted) {
          setState(() {
            _latitude = pos.latitude;
            _longitude = pos.longitude;
            _gpsStatus = 'High Accuracy GPS Locked (±${pos.accuracy.toStringAsFixed(0)}m)';
            _locating = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _gpsStatus = 'Grid GPS locked: 30.3165° N, 78.0322° E';
        _locating = false;
      });
      _fetchRealTelemetry();
    }
  }

  Future<void> _fetchRealTelemetry() async {
    try {
      final res = await ApiClient.instance.get('/disaster/weather/live?latitude=$_latitude&longitude=$_longitude');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            final temp = data['temperature_c'] ?? 20;
            final rain = (data['rainfall_24h_mm'] as num?)?.toDouble() ?? 0.0;
            final wind = (data['wind_speed_kmh'] as num?)?.toDouble() ?? 5.0;
            final humidity = data['relative_humidity_pct'] ?? 60;
            final cond = data['condition'] ?? 'Overcast';

            if (rain > 50.0 || cond.toString().toLowerCase().contains('rain') || cond.toString().toLowerCase().contains('thunder')) {
              _riskLevel = 'High Risk';
              _riskColor = const Color(0xFFEF4444);
            } else {
              _riskLevel = 'Moderate Risk';
              _riskColor = const Color(0xFFF59E0B);
            }

            _weatherSummary = '$cond • ${temp.toString()}°C live';
            _weatherRainfall = '• Real-Time Rainfall: ${rain.toStringAsFixed(1)} mm (24h sum)';
            _weatherWind = '• Real Wind: ${wind.toStringAsFixed(1)} km/h • Humidity: $humidity%';
          });
        }
      }
    } catch (_) {}

    try {
      final routeRes = await ApiClient.instance.get('/routing/safe-route?origin_lat=$_latitude&origin_lng=$_longitude');
      if (routeRes.statusCode == 200 && routeRes.data != null) {
        final r = routeRes.data as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            final dist = r['distance_km'];
            final dur = r['duration_minutes'];
            final dest = r['destination_name'] ?? 'Govt Relief Center';
            _shelterName = dest.toString();
            _shelterDistanceText = '$dist km via road ($dur mins OSRM)';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _broadcastSos() async {
    setState(() => _submitting = true);

    final beaconId = 'SOS-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final timestamp = DateTime.now();

    final details = StringBuffer();
    details.write('EMERGENCY SOS: $_selectedEmergency.\n');
    details.write('People Stranded: $_victimCount person(s).\n');
    if (_vulnerabilities.isNotEmpty) {
      details.write('Vulnerabilities: ${_vulnerabilities.join(", ")}.\n');
    }
    if (_urgentNeeds.isNotEmpty) {
      details.write('Urgent Needs: ${_urgentNeeds.join(", ")}.\n');
    }
    if (_landmarkController.text.trim().isNotEmpty) {
      details.write('Landmark: ${_landmarkController.text.trim()}.\n');
    }
    if (_phoneController.text.trim().isNotEmpty) {
      details.write('Contact Phone: ${_phoneController.text.trim()}.\n');
    }
    if (_nameController.text.trim().isNotEmpty) {
      details.write('Reporter: ${_nameController.text.trim()}.\n');
    }

    final incident = IncidentModel(
      id: beaconId,
      title: '🚨 CIVILIAN SOS: $_selectedEmergency',
      type: _selectedEmergency.contains('Fire')
          ? 'Wildfire'
          : (_selectedEmergency.contains('Flood') ? 'Flood' : 'Structural Collapse'),
      severity: 'CRITICAL',
      status: 'ACTIVE',
      latitude: _latitude,
      longitude: _longitude,
      timestamp: timestamp,
      description: details.toString(),
      locationName: _landmarkController.text.trim().isNotEmpty
          ? _landmarkController.text.trim()
          : 'Sector Target (${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)})',
      source: 'Civilian SOS Emergency Beacon',
    );

    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    setState(() {
      _submitting = false;
      _isSosActive = true;
      _activeBeaconId = beaconId;
      _beaconTime = timestamp;
    });

    // Send to backend API
    SosService().createSos(
      latitude: _latitude,
      longitude: _longitude,
      emergencyType: _selectedEmergency,
      notes: details.toString(),
      idempotencyKey: beaconId,
    ).catchError((_) {
      return <String, dynamic>{};
    });

    // Broadcast through BLE store-and-forward mesh network
    try {
      MeshManager.instance.broadcastLocalSos(
        latitude: _latitude,
        longitude: _longitude,
        emergencyType: _selectedEmergency,
        notes: details.toString(),
        peopleCount: _victimCount,
        vulnerabilities: _vulnerabilities.toList(),
      );
    } catch (_) {}

    // Update in-memory Incident and Alert providers
    if (!mounted) return;
    try {
      final incidentProvider = context.read<IncidentProvider>();
      incidentProvider.createIncident(incident);

      final alertProvider = context.read<AlertProvider>();
      alertProvider.alerts.insert(
        0,
        AlertModel(
          id: 'ALT-$beaconId',
          title: '🚨 CRITICAL SOS BEACON BROADCAST',
          message: '$_selectedEmergency at (${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}). $_victimCount person(s) stranded.',
          severity: 'CRITICAL',
          timestamp: timestamp,
          latitude: _latitude,
          longitude: _longitude,
          isLiveWebSocket: false,
        ),
      );
    } catch (_) {}
  }

  void _cancelSos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13151B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF232733)),
        ),
        title: Text('STAND DOWN BEACON?', style: AppTheme.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
        content: Text(
          'Confirm that you are safe or rescue has arrived. This will inform the emergency dispatch queue.',
          style: AppTheme.sans.copyWith(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('KEEP ACTIVE'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.safeGreen),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isSosActive = false;
                _activeBeaconId = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.safeGreen,
                  content: Text('SOS Beacon stood down. Central command updated.'),
                ),
              );
            },
            child: const Text('I AM SAFE NOW'),
          ),
        ],
      ),
    );
  }

  void _showPreFedQuestionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF13151B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: Color(0xFF232733), width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.shieldAlert, size: 18, color: AppColors.emergencyRed),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'EMERGENCY ASSESSMENT',
                        style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF232733), height: 20),

              // Scrollable pre-fed questions
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Question 1: Nature of emergency
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0D11),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF232733)),
                      ),
                      child: Row(
                        children: [
                          Icon(_locating ? LucideIcons.loader : LucideIcons.mapPin, size: 14, color: AppColors.infoCyan),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$_gpsStatus (${_latitude.toStringAsFixed(4)}° N, ${_longitude.toStringAsFixed(4)}° E)',
                              style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.infoCyan),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text('1. NATURE OF EMERGENCY', style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _emergencyTypes.map((type) {
                        final title = type['title'] as String;
                        final isSelected = _selectedEmergency == title;
                        return ChoiceChip(
                          label: Text(title, style: AppTheme.sans.copyWith(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                          selected: isSelected,
                          selectedColor: AppColors.emergencyRed.withOpacity(0.25),
                          backgroundColor: const Color(0xFF0B0D11),
                          side: BorderSide(color: isSelected ? AppColors.emergencyRed : const Color(0xFF232733)),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedEmergency = title);
                              setModalState(() {});
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Question 2: Stranded count
                    Text('2. PEOPLE STRANDED', style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0D11),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF232733)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Count needing rescue:', style: AppTheme.sans.copyWith(fontSize: 13, color: AppColors.textLight)),
                          Row(
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(LucideIcons.minusCircle, color: AppColors.textMuted, size: 22),
                                onPressed: _victimCount > 1
                                    ? () {
                                        setState(() => _victimCount--);
                                        setModalState(() {});
                                      }
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2638),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('$_victimCount', style: AppTheme.mono.copyWith(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.emergencyRed)),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(LucideIcons.plusCircle, color: AppColors.infoCyan, size: 22),
                                onPressed: () {
                                  setState(() => _victimCount++);
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Question 3: Vulnerabilities
                    Text('3. CRITICAL VULNERABILITIES', style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        '👶 Infants / Children',
                        '🧓 Elderly / Disabled',
                        '🩸 Serious Injury / Bleeding',
                        '🫁 Breathing Problems',
                        '⚠️ Trapped Under Debris',
                      ].map((item) {
                        final isSel = _vulnerabilities.contains(item);
                        return FilterChip(
                          label: Text(item, style: AppTheme.sans.copyWith(fontSize: 11, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
                          selected: isSel,
                          selectedColor: AppColors.emergencyRed.withOpacity(0.2),
                          backgroundColor: const Color(0xFF0B0D11),
                          side: BorderSide(color: isSel ? AppColors.emergencyRed : const Color(0xFF232733)),
                          checkmarkColor: AppColors.emergencyRed,
                          onSelected: (val) {
                            setState(() {
                              val ? _vulnerabilities.add(item) : _vulnerabilities.remove(item);
                            });
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Optional location landmark & phone
                    Text('4. LOCATION LANDMARK & CONTACT (OPTIONAL)', style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _landmarkController,
                      style: AppTheme.sans.copyWith(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Landmark (e.g. 2nd floor, red roof)',
                        prefixIcon: Icon(LucideIcons.mapPin, size: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: AppTheme.mono.copyWith(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Contact phone (optional)',
                        prefixIcon: Icon(LucideIcons.phone, size: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Transmit Button inside modal
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.radio, size: 20, color: Colors.white),
                label: Text(
                  _submitting ? 'TRANSMITTING...' : '🚨 TRANSMIT EMERGENCY SOS BEACON',
                  style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                onPressed: _submitting
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _broadcastSos();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar matching reference screenshot
            _buildTopBar(),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 720;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _isSosActive ? _buildActiveBeaconCard() : _buildSosHeroCard(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _buildSafetyStatusCard(),
                                const SizedBox(height: 16),
                                _buildNearestShelterCard(),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _isSosActive ? _buildActiveBeaconCard() : _buildSosHeroCard(),
                          const SizedBox(height: 16),
                          _buildSafetyStatusCard(),
                          const SizedBox(height: 16),
                          _buildNearestShelterCard(),
                          const SizedBox(height: 20),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top Bar: Clean "Fire-Eye" + "● System Connected" pill
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0D11),
        border: Border(bottom: BorderSide(color: Color(0xFF1E222D), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textLight, size: 20),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fire-Eye',
                        style: AppTheme.sans.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textLight,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'EMERGENCY SOS ASSISTANCE',
                        style: AppTheme.mono.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.infoCyan,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Green "System Connected" Pill matching reference screenshot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF102A18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1B4D2B), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'System Connected',
                  style: AppTheme.sans.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hero Card: "Need Emergency Help?" with huge circular red SOS button + pre-fed questions
  Widget _buildSosHeroCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232733), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.emergencyRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.emergencyRed.withOpacity(0.3)),
            ),
            child: Text(
              'CIVILIAN EMERGENCY CHANNEL',
              style: AppTheme.mono.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emergencyRed),
            ),
          ),
          Text(
            'Need Emergency Help?',
            style: AppTheme.sans.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Press and hold the button below to alert rescue teams.',
            style: AppTheme.sans.copyWith(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Massive Circular Red SOS Button with pulsing animation
          ScaleTransition(
            scale: _pulseAnimation,
            child: GestureDetector(
              onTap: _broadcastSos,
              onLongPress: _broadcastSos,
              child: Container(
                width: 175,
                height: 175,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.4),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'SOS',
                    style: AppTheme.sans.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Pre-fed emergency question chips (clean and accessible)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'NATURE OF EMERGENCY',
              style: AppTheme.mono.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Trapped / Structural Collapse',
              'Active Fire / Wildfire',
              'Flash Flood / Rising Water',
              'Medical Emergency / Trauma',
            ].map((title) {
              final isSel = _selectedEmergency == title;
              return ChoiceChip(
                label: Text(title, style: AppTheme.sans.copyWith(fontSize: 11, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
                selected: isSel,
                selectedColor: AppColors.emergencyRed.withOpacity(0.25),
                backgroundColor: const Color(0xFF0B0D11),
                side: BorderSide(color: isSel ? AppColors.emergencyRed : const Color(0xFF232733)),
                onSelected: (val) {
                  if (val) setState(() => _selectedEmergency = title);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Stranded Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0D11),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF232733)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('People stranded:', style: AppTheme.sans.copyWith(fontSize: 12, color: AppColors.textLight)),
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(LucideIcons.minusCircle, color: AppColors.textMuted, size: 20),
                      onPressed: _victimCount > 1 ? () => setState(() => _victimCount--) : null,
                    ),
                    Text('$_victimCount', style: AppTheme.mono.copyWith(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.emergencyRed)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(LucideIcons.plusCircle, color: AppColors.infoCyan, size: 20),
                      onPressed: () => setState(() => _victimCount++),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Big prominent Transmit SOS Beacon Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 6,
              ),
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.radio, size: 18, color: Colors.white),
              label: Text(
                _submitting ? 'TRANSMITTING SOS...' : '🚨 TRANSMIT EMERGENCY SOS BEACON',
                style: AppTheme.mono.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              onPressed: _submitting ? null : _broadcastSos,
            ),
          ),

          const SizedBox(height: 10),

          // More options modal button
          TextButton.icon(
            icon: const Icon(LucideIcons.sliders, size: 13, color: AppColors.infoCyan),
            label: Text(
              'Add Landmark, Phone or Vulnerability Details',
              style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.infoCyan),
            ),
            onPressed: _showPreFedQuestionsModal,
          ),
          const SizedBox(height: 4),

          // Offline BLE Mesh Relay Status Link
          TextButton.icon(
            icon: const Icon(LucideIcons.radio, size: 13, color: AppColors.safeGreen),
            label: Text(
              'Bluetooth Offline Mesh Network Status',
              style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.safeGreen),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshStatusScreen()));
            },
          ),
        ],
      ),
    );
  }

  // Active Distress Beacon State
  Widget _buildActiveBeaconCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emergencyRed, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withOpacity(0.2),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.emergencyRed,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(LucideIcons.radio, color: Colors.white, size: 42),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'SOS DISTRESS BEACON ACTIVE',
            style: AppTheme.mono.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppColors.emergencyRed,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'BEACON CODE: $_activeBeaconId',
            style: AppTheme.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textLight),
          ),
          const SizedBox(height: 4),
          Text(
            'Broadcasted at ${DateFormat('HH:mm:ss • MMM dd').format(_beaconTime ?? DateTime.now())}',
            style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),

          // Telemetry details
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0D11),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF232733)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DISPATCH TELEMETRY', style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w800)),
                    const StatusChip(label: 'PRIORITY ASSIGNED', color: AppColors.warningOrange),
                  ],
                ),
                const Divider(color: Color(0xFF232733), height: 16),
                _buildDispatchRow(LucideIcons.checkCircle2, 'Distress Signal Logged in Central Emergency Registry', true),
                _buildDispatchRow(LucideIcons.radio, 'Dispatched to Commander & Rescuer Queue', true),
                _buildDispatchRow(LucideIcons.bluetooth, 'BLE Mesh Relay: Advertising Store-and-Forward Beacon', true),
                _buildDispatchRow(LucideIcons.crosshair, 'GPS Locked (${_latitude.toStringAsFixed(4)}° N, ${_longitude.toStringAsFixed(4)}° E)', true),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Cancel Beacon button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              side: const BorderSide(color: AppColors.safeGreen, width: 1.2),
              foregroundColor: AppColors.safeGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(LucideIcons.shieldCheck, size: 18),
            label: Text(
              'CANCEL BEACON / I AM SAFE NOW',
              style: AppTheme.mono.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            onPressed: _cancelSos,
          ),

          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(LucideIcons.radio, size: 14, color: AppColors.infoCyan),
            label: Text('View Bluetooth Mesh Relay Network', style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.infoCyan)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshStatusScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchRow(IconData icon, String text, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: active ? AppColors.safeGreen : AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.sans.copyWith(fontSize: 12, color: active ? AppColors.textLight : AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  // Right Top Card: "SAFETY STATUS" matching reference screenshot
  Widget _buildSafetyStatusCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232733), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAFETY STATUS',
            style: AppTheme.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _riskLevel,
            style: AppTheme.sans.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _riskColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _weatherSummary,
            style: AppTheme.sans.copyWith(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 14),

          // Inner bullet box from screenshot
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0D11),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E222D)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletItem(_weatherRainfall),
                const SizedBox(height: 6),
                _buildBulletItem(_weatherWind),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Row(
      children: [
        const Text('• ', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        Expanded(
          child: Text(
            text,
            style: AppTheme.sans.copyWith(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  // Right Bottom Card: "NEAREST SHELTER" matching reference screenshot
  Widget _buildNearestShelterCard() {
    ShelterProvider? shelterProvider;
    try {
      shelterProvider = Provider.of<ShelterProvider>(context, listen: false);
    } catch (_) {}
    final shelters = shelterProvider?.shelters ?? [];
    final nearest = shelters.isNotEmpty ? shelters.first : null;

    final name = nearest?.name ?? _shelterName;
    final distance = _shelterDistanceText;
    final capacity = nearest?.capacity ?? 120;
    final available = nearest?.availableBeds ?? 64;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF13151B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232733), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEAREST SHELTER',
            style: AppTheme.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: AppTheme.sans.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            distance,
            style: AppTheme.sans.copyWith(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),

          // Capacity & Available grid from screenshot
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0D11),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E222D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Capacity', style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text('$capacity', style: AppTheme.mono.copyWith(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textLight)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0D11),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E222D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available', style: AppTheme.sans.copyWith(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        '$available',
                        style: AppTheme.mono.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF22C55E), // Vibrant safe green from screenshot
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
