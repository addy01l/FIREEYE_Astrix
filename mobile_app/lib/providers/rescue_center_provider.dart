import 'package:flutter/foundation.dart';
import '../models/rescue_center_model.dart';
import '../services/rescue_center_service.dart';

class RescueCenterProvider extends ChangeNotifier {
  final RescueCenterService _service = RescueCenterService();

  List<RescueCenterModel> _centers = [];
  bool _isLoading = false;

  List<RescueCenterModel> get centers => _centers;
  bool get isLoading => _isLoading;

  int get totalPersonnel => _centers.fold(0, (sum, c) => sum + c.activePersonnel);
  int get totalVehicles => _centers.fold(0, (sum, c) => sum + c.availableVehicles);

  RescueCenterProvider() {
    fetchRescueCenters();
  }

  Future<void> fetchRescueCenters() async {
    _isLoading = true;
    notifyListeners();
    try {
      _centers = await _service.getRescueCenters();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }
}

