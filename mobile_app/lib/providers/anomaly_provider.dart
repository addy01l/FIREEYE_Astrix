import 'package:flutter/foundation.dart';
import '../models/anomaly_model.dart';
import '../services/anomaly_service.dart';

class AnomalyProvider extends ChangeNotifier {
  final AnomalyService _anomalyService = AnomalyService();

  List<AnomalyModel> _anomalies = [];
  bool _isLoading = false;
  bool _isBackendOnline = false;
  String? _errorMessage;

  List<AnomalyModel> get anomalies => _anomalies;
  bool get isLoading => _isLoading;
  bool get isBackendOnline => _isBackendOnline;
  String? get errorMessage => _errorMessage;

  AnomalyProvider() {
    checkHealthAndFetch();
  }

  Future<void> checkHealthAndFetch() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isBackendOnline = await _anomalyService.checkBackendHealth();
      if (_isBackendOnline) {
        _anomalies = await _anomalyService.fetchLiveAnomalies();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isBackendOnline = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}

