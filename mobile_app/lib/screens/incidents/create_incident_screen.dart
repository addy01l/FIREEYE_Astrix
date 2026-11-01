import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/incident_model.dart';
import '../../providers/incident_provider.dart';

class CreateIncidentScreen extends StatefulWidget {
  const CreateIncidentScreen({super.key});

  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  String _type = 'Industrial Fire';
  String _severity = 'CRITICAL';
  bool _locating = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _fetchGPS() async {
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
        setState(() {
          _latController.text = pos.latitude.toStringAsFixed(4);
          _lngController.text = pos.longitude.toStringAsFixed(4);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;
    final latitude = double.tryParse(_latController.text);
    final longitude = double.tryParse(_lngController.text);
    if (latitude == null || longitude == null || latitude.abs() > 90 || longitude.abs() > 180) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provide valid GPS coordinates or capture your current location.')));
      return;
    }
    setState(() => _submitting = true);

    final inc = IncidentModel(
      id: 'INC-${DateTime.now().millisecondsSinceEpoch % 10000}',
      title: _titleController.text.trim(),
      type: _type,
      severity: _severity,
      status: 'ACTIVE',
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      description: _descController.text.trim(),
      locationName: _locationController.text.trim(),
      source: 'Field Operator Report',
    );

    final provider = context.read<IncidentProvider>();
    final ok = await provider.createIncident(inc);

    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency incident successfully logged into central registry!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('LOG EMERGENCY INCIDENT', style: AppTheme.mono.copyWith(fontSize: 14)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Incident Title
                TextFormField(
                  controller: _titleController,
                  style: AppTheme.sans.copyWith(fontSize: 14),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter incident headline' : null,
                  decoration: const InputDecoration(
                    labelText: 'Incident Headline / Title',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: 'e.g. Chemical storage fire or brush fire',
                    prefixIcon: Icon(LucideIcons.flame, size: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Disaster Type & Severity Level Dropdowns
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _type,
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: AppColors.darkSurfaceElevated,
                        decoration: const InputDecoration(
                          labelText: 'Disaster Type',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        selectedItemBuilder: (context) {
                          return [
                            'Industrial Fire',
                            'Wildfire',
                            'Landslide',
                            'Flash Flood',
                            'Structural Collapse',
                          ].map((val) {
                            return Text(
                              val,
                              style: AppTheme.sans.copyWith(fontSize: 13, color: AppColors.textLight),
                              overflow: TextOverflow.ellipsis,
                            );
                          }).toList();
                        },
                        items: const [
                          DropdownMenuItem(value: 'Industrial Fire', child: Text('Industrial Fire', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Wildfire', child: Text('Wildfire', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Landslide', child: Text('Landslide', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Flash Flood', child: Text('Flash Flood', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Structural Collapse', child: Text('Structural Collapse', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _type = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _severity,
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: AppColors.darkSurfaceElevated,
                        decoration: const InputDecoration(
                          labelText: 'Severity Level',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        selectedItemBuilder: (context) {
                          return ['CRITICAL', 'WARNING', 'WATCH'].map((val) {
                            return Text(
                              val,
                              style: AppTheme.mono.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: val == 'CRITICAL'
                                    ? AppColors.emergencyRed
                                    : val == 'WARNING'
                                        ? AppColors.warningOrange
                                        : AppColors.infoCyan,
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          }).toList();
                        },
                        items: const [
                          DropdownMenuItem(value: 'CRITICAL', child: Text('CRITICAL')),
                          DropdownMenuItem(value: 'WARNING', child: Text('WARNING')),
                          DropdownMenuItem(value: 'WATCH', child: Text('WATCH')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _severity = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Location Name
                TextFormField(
                  controller: _locationController,
                  style: AppTheme.sans.copyWith(fontSize: 13),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter facility or street address' : null,
                  decoration: const InputDecoration(
                    labelText: 'Location Name / Landmarks',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: 'e.g. Selaqui Industrial Area, Sector 4',
                    prefixIcon: Icon(LucideIcons.mapPin, size: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. GPS Inputs with Auto-detect Current Location Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTheme.mono.copyWith(fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: '30.3165',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTheme.mono.copyWith(fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: '78.0322',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Auto-detect GPS',
                      child: SizedBox(
                        height: 48,
                        width: 48,
                        child: Material(
                          color: AppColors.darkSurfaceElevated,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppColors.darkBorder),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _locating ? null : _fetchGPS,
                            child: Center(
                              child: _locating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.infoCyan),
                                    )
                                  : const Icon(LucideIcons.crosshair, color: AppColors.infoCyan, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Incident Description
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  style: AppTheme.sans.copyWith(fontSize: 13),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter situation briefing' : null,
                  decoration: const InputDecoration(
                    labelText: 'Situation Briefing & Hazards',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: 'Describe fire progression, casualties, hazards, access routes...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Submit Button
                ElevatedButton(
                  onPressed: _submitting ? null : _submitIncident,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.emergencyRed,
                  ),
                  child: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('TRANSMIT TO REGISTRY'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
