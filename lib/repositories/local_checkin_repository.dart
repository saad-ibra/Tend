import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_energy_checkin.dart';
import 'checkin_repository.dart';

class LocalCheckInRepository implements CheckInRepository {
  static const String _storageKey = 'tend_check_ins_v1';
  final SharedPreferences? prefs;

  LocalCheckInRepository({this.prefs});

  Future<SharedPreferences> _getPrefs() async {
    return prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<List<MoodEnergyCheckIn>> getCheckIns() async {
    final sp = await _getPrefs();
    final rawList = sp.getStringList(_storageKey);

    if (rawList == null) {
      return [];
    }

    final list = rawList
        .map((str) => MoodEnergyCheckIn.fromJson(jsonDecode(str) as Map<String, dynamic>))
        .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<MoodEnergyCheckIn?> getCheckInForDate(String dateKey) async {
    final all = await getCheckIns();
    try {
      return all.firstWhere((c) => c.dateKey == dateKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCheckIn(MoodEnergyCheckIn checkIn) async {
    final sp = await _getPrefs();
    final all = await getCheckIns();

    // Check if an entry already exists for this dateKey or id
    final idx = all.indexWhere((c) => c.id == checkIn.id || c.dateKey == checkIn.dateKey);

    if (idx >= 0) {
      all[idx] = checkIn;
    } else {
      all.insert(0, checkIn);
    }

    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _saveAll(all, sp);
  }

  @override
  Future<void> deleteCheckIn(String id) async {
    final sp = await _getPrefs();
    final all = await getCheckIns();
    all.removeWhere((c) => c.id == id);
    await _saveAll(all, sp);
  }

  Future<void> _saveAll(List<MoodEnergyCheckIn> list, SharedPreferences sp) async {
    final encoded = list.map((c) => jsonEncode(c.toJson())).toList();
    await sp.setStringList(_storageKey, encoded);
  }
}
