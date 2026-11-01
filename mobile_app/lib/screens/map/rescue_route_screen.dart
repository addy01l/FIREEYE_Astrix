import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../models/incident_model.dart';
import '../../providers/incident_provider.dart';

/// Requests a road route from the configured routing service and shows only
/// server-returned route geometry. No straight-line route is presented as safe.
class RescueRouteScreen extends StatefulWidget {
  final IncidentModel incident;
  final bool routeToShelter;

  const RescueRouteScreen({super.key, required this.incident, this.routeToShelter = false});

  @override
  State<RescueRouteScreen> createState() => _RescueRouteScreenState();
}

class _RescueRouteScreenState extends State<RescueRouteScreen> {
  Map<String, dynamic>? _route;
  String? _error;
  bool _loading = true;
  bool _updating = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever || permission == LocationPermission.unableToDetermine) {
        throw StateError('Location permission is required to calculate a route from your current position.');
      }
      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
      final body = <String, dynamic>{'origin': {'lat': position.latitude, 'lng': position.longitude}, 'avoid_high_risk': true};
      if (widget.routeToShelter) {
        final sheltersResponse = await ApiClient.instance.get('/api/v1/shelters/');
        final shelters = sheltersResponse.data as List? ?? const [];
        final hasAvailableShelter = shelters.whereType<Map>().any((shelter) =>
            shelter['is_safe'] == true &&
            (shelter['available_beds'] as num? ?? 0) > 0);
        if (!hasAvailableShelter) {
          throw StateError('No safe shelter with available capacity is registered. Your SOS remains active; contact command center for shelter guidance.');
        }
        // Omitting destination asks the backend for the nearest available shelter.
      } else {
        body['destination'] = {'lat': widget.incident.latitude, 'lng': widget.incident.longitude};
      }
      final response = await ApiClient.instance.post('/api/v1/routing/safe-route', data: body);
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['path'] is! List || (data['path'] as List).length < 2) throw StateError('Routing service did not return verified road geometry.');
      final routeStatus = data['routing_status'];
      if (routeStatus == 'DEGRADED_STRAIGHT_LINE' ||
          (data['is_verified_safe'] != true && routeStatus != 'ROAD_ROUTE_HAZARD_AVOIDANCE_UNVERIFIED')) {
        throw StateError(data['warning']?.toString() ?? 'A usable road route is unavailable. No direct-line guidance will be shown.');
      }
      if (mounted) setState(() { _route = data; _loading = false; });
    } catch (e) {
      final message = e is DioException
          ? ((e.response?.data is Map ? (e.response?.data as Map)['detail']?.toString() : null) ??
              (e.response?.statusCode == 404
                  ? 'No operational shelter is registered. Your SOS remains active; contact command center for guidance.'
                  : e.response?.statusCode == 503
                  ? 'Shelter routing is temporarily unavailable. Your SOS remains active.'
                  : e.message ?? 'Shelter routing is unavailable.'))
          : e.toString().replaceFirst('Bad state: ', '');
      if (mounted) setState(() { _error = message; _loading = false; });
    }
  }

  Future<void> _setStatus(String value) async {
    setState(() => _updating = true);
    final ok = await context.read<IncidentProvider>().updateStatus(widget.incident.id, value);
    if (!mounted) return;
    setState(() { _updating = false; if (ok) _status = value; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Request updated: $value' : 'Update rejected by the server. Check your role and connection.')));
  }

  @override
  Widget build(BuildContext context) {
    final path = (_route?['path'] as List? ?? []).map((p) {
      final pair = p as List;
      return LatLng((pair[0] as num).toDouble(), (pair[1] as num).toDouble());
    }).toList();
    final title = widget.routeToShelter ? 'Nearest shelter route' : 'Rescue route';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.route, size: 42), const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton(onPressed: () { setState(() { _loading = true; _error = null; }); _loadRoute(); }, child: const Text('Retry'))])))
          : Column(children: [
              Material(color: Theme.of(context).colorScheme.surface, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_route?['destination_name']?.toString() ?? (widget.routeToShelter ? 'Shelter' : widget.incident.title), style: Theme.of(context).textTheme.titleMedium), if (!widget.routeToShelter) Text('${widget.incident.severity}  •  ${_status ?? widget.incident.status}  •  ${widget.incident.type}'), if (!widget.routeToShelter && widget.incident.description.isNotEmpty) Text(widget.incident.description, maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 8), Text('${_route?['distance_km']} km  •  ${_route?['duration_minutes']} min ETA'), const SizedBox(height: 4), Text(_route?['hazard_status']?.toString() ?? 'Route status unavailable'), if (_route?['warning'] != null) Text(_route!['warning'].toString(), style: TextStyle(color: Theme.of(context).colorScheme.error))]))),
              if (!widget.routeToShelter) Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [Expanded(child: OutlinedButton(onPressed: _updating ? null : () => _setStatus('DISPATCHED'), child: const Text('DISPATCH TEAM'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: _updating ? null : () => _setStatus('RESCUED'), child: const Text('MARK RESCUED')))])),
              Expanded(child: FlutterMap(options: MapOptions(initialCameraFit: CameraFit.bounds(bounds: LatLngBounds.fromPoints(path), padding: const EdgeInsets.all(48))), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.fireeye.app'), PolylineLayer(polylines: [Polyline(points: path, color: Colors.blue, strokeWidth: 5)]), MarkerLayer(markers: [Marker(point: path.first, width: 42, height: 42, child: const Icon(Icons.my_location, color: Colors.blue, size: 32)), Marker(point: path.last, width: 42, height: 42, child: Icon(widget.routeToShelter ? Icons.home : Icons.emergency, color: Colors.red, size: 32))])])),
              if ((_route?['steps'] as List?)?.isNotEmpty == true) SizedBox(height: 150, child: ListView(children: [for (final step in _route!['steps'] as List) ListTile(dense: true, leading: const Icon(Icons.turn_right), title: Text((step as Map)['instruction'].toString()), subtitle: Text('${step['distance_m']} m  •  ${step['safety_status']}'))]))
            ]),
    );
  }
}
