import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  final String person1Name;
  final String person2Name;
  final String coupleId;
  final String whoAmI; // 'person1' or 'person2'

  AppConfig({
    required this.person1Name,
    required this.person2Name,
    required this.coupleId,
    required this.whoAmI,
  });

  Map<String, dynamic> toJson() => {
        'person1Name': person1Name,
        'person2Name': person2Name,
        'coupleId': coupleId,
        'whoAmI': whoAmI,
      };

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        person1Name: json['person1Name'] ?? 'Persona 1',
        person2Name: json['person2Name'] ?? 'Persona 2',
        coupleId: json['coupleId'] ?? 'default-couple',
        whoAmI: json['whoAmI'] ?? 'person1',
      );

  String get myName => whoAmI == 'person1' ? person1Name : person2Name;
  String get partnerName => whoAmI == 'person1' ? person2Name : person1Name;
  String get partnerKey => whoAmI == 'person1' ? 'person2' : 'person1';
}

class ConfigService {
  static const _key = 'distanceTrackerConfig';

  static Future<AppConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) return null;
    return AppConfig.fromJson(jsonDecode(saved));
  }

  static Future<void> saveConfig(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(config.toJson()));
  }

  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
