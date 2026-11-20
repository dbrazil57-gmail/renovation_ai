import 'package:hive_ce/hive_ce.dart';

import 'feedback.dart';

abstract class FeedbackDrafts {
  FeedbackDraft read();
  Future<void> save(FeedbackDraft draft);
}

class LocalFeedbackDrafts implements FeedbackDrafts {
  final Box<dynamic> records;
  LocalFeedbackDrafts(this.records);
  static const key = 'settings:feedback_draft';
  @override
  FeedbackDraft read() => FeedbackDraft.fromMap(records.get(key));
  @override
  Future<void> save(FeedbackDraft draft) => records.put(key, draft.toMap());
}
