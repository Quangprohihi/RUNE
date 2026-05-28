import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../models/analytics_summary.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider(this._api);

  final ApiClient _api;
  AnalyticsSummary _summary = AnalyticsSummary.empty();
  bool _isLoading = false;
  String? _error;

  AnalyticsSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response =
          await _api.get('/analytics/summary') as Map<String, dynamic>;
      _summary = AnalyticsSummary.fromJson(response);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
