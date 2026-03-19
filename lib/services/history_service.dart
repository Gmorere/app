import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emotion_record.dart';

class HistoryService {
  static const String _storageKey = 'emotion_history_records';
  static final List<EmotionRecord> _records = [];
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
          _records.add(EmotionRecord.fromJson(decoded));
        } else {
          debugPrint('HistoryService: registro ignorado por formato inválido.');
        }
      } catch (e, st) {
        debugPrint('HistoryService: error leyendo registro: $e');
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

  static Future<void> addRecord(EmotionRecord record) async {
    await init();
    _records.add(record);
    await _save();
  }

  static List<EmotionRecord> getRecords() {
    return List.unmodifiable(_records);
  }

  static Future<void> clear() async {
    await init();
    _records.clear();
    await _save();
  }
}