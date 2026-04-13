import 'dart:convert';

import 'package:myapp/models/saved_stack.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StackService {
  static const _key = 'v1_saved_stack';

  Future<SavedStack?> getStack() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return SavedStack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveStack(SavedStack stack) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(stack.toJson()));
  }

  Future<void> deleteStack() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<bool> hasStack() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }
}
