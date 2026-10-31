import 'package:flutter/foundation.dart';
import '../core/utils/error_handler.dart';
import '../models/incident_model.dart';
import '../services/incident_service.dart';

class IncidentProvider extends ChangeNotifier {
  final IncidentService _incidentService = IncidentService();

  List<IncidentModel> _incidents = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filter = 'ALL'; // ALL, CRITICAL, WARNING, RESOLVED

  List<IncidentModel> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _filter;

  List<IncidentModel> get filteredIncidents {
    if (_filter == 'ALL') return _incidents;
    if (_filter == 'CRITICAL') return _incidents.where((i) => i.severity == 'CRITICAL').toList();
    if (_filter == 'WARNING') return _incidents.where((i) => i.severity == 'WARNING').toList();
    if (_filter == 'RESOLVED') return _incidents.where((i) => i.status == 'RESOLVED').toList();
    return _incidents;
  }

  int get criticalCount => _incidents.where((i) => i.severity == 'CRITICAL' && i.status != 'RESOLVED').length;
  int get activeCount => _incidents.where((i) => i.status == 'ACTIVE').length;

  IncidentProvider() {
    fetchIncidents();
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> fetchIncidents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _incidents = await _incidentService.getIncidents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = ErrorHandler.formatGeneralError(e);
      notifyListeners();
    }
  }

  Future<bool> createIncident(IncidentModel incident) async {
    final success = await _incidentService.createIncident(incident);
    if (success) {
      await fetchIncidents();
    }
    return success;
  }

  Future<bool> updateStatus(String id, String newStatus) async {
    final success = await _incidentService.updateIncidentStatus(id, newStatus);
    if (success) {
      final idx = _incidents.indexWhere((i) => i.id == id);
      if (idx != -1) {
        _incidents[idx] = _incidents[idx].copyWith(status: newStatus);
        notifyListeners();
      }
    }
    return success;
  }
}

