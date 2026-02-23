import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../data/models/health_tip_model.dart';
import '../../data/models/recent_analysis_model.dart';
import '../../data/local/health_tips_data.dart';
import '../../data/local/recent_analysis_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeViewModel extends ChangeNotifier {
  RecentAnalysisModel? _recentAnalysis;
  HealthTipModel? _currentTip;
  bool _isLoading = true;

  RecentAnalysisModel? get recentAnalysis => _recentAnalysis;
  HealthTipModel? get currentTip => _currentTip;
  bool get isLoading => _isLoading;

  HomeViewModel() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _recentAnalysis = await RecentAnalysisStorage.load();

    if (_recentAnalysis == null) {
      await _loadDailyTip();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadDailyTip() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month}-${today.day}';

    final savedDate = prefs.getString('last_tip_date');
    final savedIndex = prefs.getInt('last_tip_index');

    if (savedDate == dateString &&
        savedIndex != null &&
        savedIndex < HealthTipsData.tips.length) {
      _currentTip = HealthTipsData.tips[savedIndex];
    } else {
      final newIndex = Random().nextInt(HealthTipsData.tips.length);
      _currentTip = HealthTipsData.tips[newIndex];

      await prefs.setString('last_tip_date', dateString);
      await prefs.setInt('last_tip_index', newIndex);
    }
  }
}
