import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/pill.dart';

class ProductService {
  static Future<List<AmericanPill>> loadUSTop10() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/us_top_10.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => AmericanPill.fromJson(json)).toList();
    } catch (e) {
      // In production, log the error to a service like Sentry or Firebase Crashlytics
      print('Error loading US Top 10 data: $e');
      return [];
    }
  }
}
