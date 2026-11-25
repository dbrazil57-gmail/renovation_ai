import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'ai_model_choices.dart';
import 'ai_types.dart';

enum AiOperation { connection, analysis, design }

/// Small device-only log. Never accepts request bodies, headers, provider error
/// text, keys, photo bytes, project names or user instructions.
class AiDiagnostics extends ChangeNotifier {
  static const limit = 40;
  final _entries = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> get entries => _entries.reversed
      .map((e) => Map<String, dynamic>.unmodifiable(e))
      .toList();
  String get report => const JsonEncoder.withIndent('  ').convert(_entries);

  void restore(Object? saved) {
    if (saved is! List) return;
    _entries.clear();
    for (final raw
        in saved
            .whereType<Map>()
            .toList()
            .reversed
            .take(limit)
            .toList()
            .reversed) {
      final time = DateTime.tryParse(raw['time'].toString());
      final operation = AiOperation.values
          .where((e) => e.name == raw['operation'])
          .firstOrNull;
      final provider = AiProvider.values
          .where((e) => e.name == raw['provider'])
          .firstOrNull;
      final problem = AiProblem.values
          .where((e) => e.name == raw['problem'])
          .firstOrNull;
      if (time == null ||
          operation == null ||
          provider == null ||
          (raw['ok'] != true && problem == null)) {
        continue;
      }
      _entries.add(
        _entry(
          time,
          operation,
          provider,
          raw['model'],
          raw['quality'],
          raw['elapsedMs'],
          raw['ok'] == true,
          problem,
          raw['http'],
        ),
      );
    }
  }

  static Map<String, dynamic> _entry(
    DateTime time,
    AiOperation operation,
    AiProvider provider,
    Object? model,
    Object? quality,
    Object? elapsed,
    bool ok,
    AiProblem? problem,
    Object? http,
  ) => {
    'time': time.toUtc().toIso8601String(),
    'operation': operation.name,
    'provider': provider.name,
    'transport': provider == AiProvider.gemini
        ? 'generateContent'
        : 'configured',
    'model':
        [
          ...preferredRoomImageModels,
          ...geminiRoomImageModels,
          ...geminiAnalysisModels,
          'gpt-6-luna',
          'gpt-4.1-mini',
          'gpt-4o-mini',
        ].contains(model)
        ? model
        : 'other',
    if (['low', 'medium', 'high'].contains(quality)) 'quality': quality,
    'elapsedMs': elapsed is int ? elapsed.clamp(0, 86400000) : 0,
    'ok': ok,
    if (!ok) 'problem': (problem ?? AiProblem.unknown).name,
    if (http is int && http >= 100 && http <= 599) 'http': http,
  };

  void record({
    required AiOperation operation,
    required AiProvider provider,
    String? model,
    String? quality,
    required Duration elapsed,
    AiFailure? failure,
    bool ok = true,
  }) {
    _entries.add(
      _entry(
        DateTime.now(),
        operation,
        provider,
        model,
        quality,
        elapsed.inMilliseconds,
        ok,
        failure?.problem,
        failure?.statusCode,
      ),
    );
    if (_entries.length > limit) _entries.removeAt(0);
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
