import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EventOverridesRepository {
  static const _key = 'event_volume_overrides';
  final SharedPreferences _prefs;

  EventOverridesRepository(this._prefs);

  Future<Map<String, double>> loadOverrides() async {
    final jsonStr = _prefs.getString(_key);
    if (jsonStr == null) return {};

    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
  }

  Future<void> saveOverrides(Map<String, double> overrides) async {
    final jsonStr = jsonEncode(overrides);
    await _prefs.setString(_key, jsonStr);
  }
}
