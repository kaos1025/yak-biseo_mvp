import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recent_analysis_model.dart';

class RecentAnalysisStorage {
  static const String _key = 'recent_analysis_v1';

  static Future<void> save(RecentAnalysisModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(model.toJson()));
  }

  static Future<RecentAnalysisModel?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return RecentAnalysisModel.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
