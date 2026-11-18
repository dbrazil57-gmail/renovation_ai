import 'package:flutter/foundation.dart';

enum AiStage {
  idle,
  preparing,
  waiting,
  reading,
  saving,
  completed,
  failed,
  saveFailed,
}

/// Observable client activity, not a claimed percentage of provider work.
class AiActivity extends ChangeNotifier {
  final DateTime Function() now;
  AiActivity({DateTime Function()? now}) : now = now ?? DateTime.now;
  AiStage stage = AiStage.idle;
  String? roomId;
  String operation = '';
  String detail = '';
  DateTime? startedAt, updatedAt, finishedAt;
  bool get active => {
    AiStage.preparing,
    AiStage.waiting,
    AiStage.reading,
    AiStage.saving,
  }.contains(stage);
  Duration get elapsed => startedAt == null
      ? Duration.zero
      : (finishedAt ?? now()).difference(startedAt!);

  void begin({required String roomId, required String operation}) {
    if (active) throw StateError('Another AI task is still running.');
    this.roomId = roomId;
    this.operation = operation;
    startedAt = now();
    finishedAt = null;
    update(AiStage.preparing);
  }

  void update(AiStage value, {String detail = ''}) {
    stage = value;
    this.detail = detail;
    updatedAt = now();
    if (!active) finishedAt = updatedAt;
    notifyListeners();
  }

  void dismiss() {
    if (active) return;
    stage = AiStage.idle;
    roomId = null;
    notifyListeners();
  }

  String get label => switch (stage) {
    AiStage.idle => '',
    AiStage.preparing => '$operation: preparing request',
    AiStage.waiting => '$operation: sending / waiting for AI',
    AiStage.reading => '$operation: reading response',
    AiStage.saving => '$operation: saving on this device',
    AiStage.completed => '$operation saved',
    AiStage.failed => '$operation did not finish',
    AiStage.saveFailed => 'AI result received · saving needs attention',
  };
}
