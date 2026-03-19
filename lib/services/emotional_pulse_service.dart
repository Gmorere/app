import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emotional_pulse_record.dart';

class EmotionalPulseService {
  static const String _storageKey = 'emotional_pulse_records';
  static final List<EmotionalPulseRecord> _records = [];
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? [];

    _records.clear();

    for (final item in stored) {
      try {
        final decoded = jsonDecode(item);

        if (decoded is Map<String, dynamic>) {
          _records.add(EmotionalPulseRecord.fromJson(decoded));
        } else {
          debugPrint(
            'EmotionalPulseService: registro ignorado por formato inválido.',
          );
        }
      } catch (e, st) {
        debugPrint('EmotionalPulseService: error leyendo registro: $e');
        debugPrintStack(stackTrace: st);
      }
    }

    _initialized = true;
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _records.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_storageKey, encoded);
  }

  static Future<void> addRecord(EmotionalPulseRecord record) async {
    await init();
    _records.add(record);
    await _save();
  }

  static List<EmotionalPulseRecord> getRecords() {
    return List.unmodifiable(_records);
  }

  static EmotionalPulseRecord? getLatestRecord() {
    if (_records.isEmpty) return null;
    return _records.last;
  }

  static EmotionalPulseRecord? getLatestRecentRecord({
    Duration maxAge = const Duration(hours: 24),
  }) {
    if (_records.isEmpty) return null;

    final latest = _records.last;
    final now = DateTime.now();

    if (now.difference(latest.timestamp) <= maxAge) {
      return latest;
    }

    return null;
  }

  static bool hasRecentRecord({
    Duration maxAge = const Duration(hours: 24),
  }) {
    return getLatestRecentRecord(maxAge: maxAge) != null;
  }

  static Future<void> clear() async {
    await init();
    _records.clear();
    await _save();
  }
}