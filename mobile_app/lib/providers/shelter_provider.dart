import 'package:flutter/foundation.dart';
import '../models/shelter_model.dart';
import '../services/shelter_service.dart';

class ShelterProvider extends ChangeNotifier {
  final ShelterService _service = ShelterService();

  List<ShelterModel> _shelters = [];
  bool _isLoading = false;

  List<ShelterModel> get shelters => _shelters;
  bool get isLoading => _isLoading;

  int get totalCapacity => _shelters.fold(0, (sum, s) => sum + s.capacity);
  int get totalOccupancy => _shelters.fold(0, (sum, s) => sum + s.occupancy);
  int get totalAvailable => totalCapacity - totalOccupancy;

  ShelterProvider() {
    fetchShelters();
  }

  Future<void> fetchShelters() async {
    _isLoading = true;
    notifyListeners();
    try {
      _shelters = await _service.getShelters();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }
}

