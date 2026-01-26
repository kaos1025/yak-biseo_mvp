import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pill.dart';

class MyPillService {
  static const String _storageKey = 'my_pills_data';

  /// Loads the list of saved pills from local storage.
  static Future<List<KoreanPill>> loadMyPills() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => KoreanPill.fromJson(e)).toList();
    } catch (e) {
      // If parsing fails (e.g. schema change), return empty list or handle error
      return [];
    }
  }

  /// Saves a pill to local storage.
  /// Returns check code: 0=Success, 1=Already Exists
  static Future<int> savePill(KoreanPill newPill) async {
    final prefs = await SharedPreferences.getInstance();
    final pills = await loadMyPills();

    // Check for duplicates (by ID) -- Assuming ID is unique report number
    final isDuplicate = pills.any((p) => p.id == newPill.id);
    if (isDuplicate) {
      return 1; // Already Exists
    }

    pills.insert(0, newPill); // Add to top

    final String jsonString = jsonEncode(pills.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
    return 0; // Success
  }

  /// Removes a pill by ID.
  static Future<void> removePill(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<KoreanPill> pills = await loadMyPills();

    pills.removeWhere((p) => p.id == id);

    final String jsonString = jsonEncode(pills.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}
