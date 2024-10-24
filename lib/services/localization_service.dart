import 'dart:convert';
import 'package:flutter/services.dart';

class LocalizationService {
  static Map<String, dynamic>? _localizedStrings;
  static Future<void> load(String languageCode) async {
    try {
      String jsonString = await rootBundle.loadString('assets/translations/$languageCode.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap;
    } catch (e) {
      print("Error loading localization file for $languageCode: $e");
      String fallbackJsonString = await rootBundle.loadString('assets/translations/en.json');
      Map<String, dynamic> fallbackJsonMap = json.decode(fallbackJsonString);
      _localizedStrings = fallbackJsonMap;
    }
  }

  static String translate(String key) {
    if (_localizedStrings == null) return key;
    List<String> keys = key.split('.');
    dynamic value = _localizedStrings;
    for (String k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key;
      }
    }
    return value?.toString() ?? key;
  }
}
