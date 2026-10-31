import 'package:flutter/foundation.dart';
import '../models/victim_model.dart';
import '../services/victim_service.dart';

class VictimProvider extends ChangeNotifier {
  final VictimService _service = VictimService();

  List<VictimModel> _victims = [];
  bool _isLoading = false;

  List<VictimModel> get victims => _victims;
  bool get isLoading => _isLoading;

  int get trappedCount => _victims.where((v) => v.status == 'TRAPPED').length;
  int get inTransitCount => _victims.where((v) => v.status == 'IN TRANSIT').length;
  int get rescuedCount => _victims.where((v) => v.status == 'RESCUED').length;

  VictimProvider() {
    fetchVictims();
  }

  Future<void> fetchVictims() async {
    _isLoading = true;
    notifyListeners();
    try {
      _victims = await _service.getVictims();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateStatus(String id, String newStatus, {String? notes}) async {
    final success = await _service.updateVictimStatus(id, newStatus, notes: notes);
    if (success) {
      final idx = _victims.indexWhere((v) => v.id == id);
      if (idx != -1) {
        _victims[idx] = _victims[idx].copyWith(status: newStatus, medicalCondition: notes);
        notifyListeners();
      }
    }
    return success;
  }
}

