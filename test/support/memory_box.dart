import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

/// Disposable storage for widget tests on Chrome and the VM.
class MemoryBox extends Fake implements Box<dynamic> {
  final Map<dynamic, dynamic> entries = {};
  @override
  String? get path => null;
  @override
  Iterable<dynamic> get keys => entries.keys;
  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      entries[key] ?? defaultValue;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    entries[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    entries.remove(key);
  }
}
