import 'dart:convert';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VolumeRulesRepository {
  static const _key = 'volume_rules';
  final SharedPreferences _prefs;

  VolumeRulesRepository(this._prefs);

  Future<List<VolumeRule>> loadRules() async {
    final list = _prefs.getStringList(_key);
    if (list == null) return [];
    return list
        .map((e) => VolumeRule.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRules(List<VolumeRule> rules) async {
    final list = rules.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_key, list);
  }
}
