import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive_ce.dart';

import 'models.dart';

/// A reviewed, single-project removal plan. External files are never targets.
class ArchiveRemovalPlan {
  final RenovationProject project;
  final Map<String, dynamic> records;
  final Map<String, dynamic> images;
  final int roomCount, designCount, imageBytes;
  final String revision;
  ArchiveRemovalPlan._(
    this.project,
    this.records,
    this.images,
    this.roomCount,
    this.designCount,
    this.imageBytes,
    this.revision,
  );

  factory ArchiveRemovalPlan.inspect(
    Box<dynamic> records,
    Box<dynamic> photos,
    String projectId,
  ) {
    final rawProject = records.get('project:$projectId');
    if (rawProject is! Map ||
        (rawProject['archived'] != true && rawProject['deleted'] != true)) {
      throw StateError(
        'Only an archived or deleted project can be cleaned up.',
      );
    }
    final project = RenovationProject.fromMap(rawProject);
    final removal = <String, dynamic>{'project:$projectId': rawProject};
    final roomIds = <String>{};
    for (final key in records.keys.whereType<String>().toList()) {
      final value = records.get(key);
      if (key.startsWith('room:') &&
          value is Map &&
          value['projectId'] == projectId) {
        removal[key] = value;
        roomIds.add(key.substring(5));
      }
    }
    var designCount = 0;
    for (final key in records.keys.whereType<String>().toList()) {
      final value = records.get(key);
      if (key.startsWith('design:') &&
          value is Map &&
          roomIds.contains(value['roomId'])) {
        removal[key] = value;
        designCount++;
      }
      if (roomIds.any((id) => key.startsWith('settings:brief_review:$id:')) ||
          ((key == 'settings:home_cover' || key == 'settings:resume') &&
              value is Map &&
              roomIds.contains(value['roomId']))) {
        removal[key] = value;
      }
    }
    final photoKeys = photos.keys.whereType<String>().toSet();
    void references(Object? value, Set<String> into) {
      if (value is String) {
        if (photoKeys.contains(value)) into.add(value);
      } else if (value is Map) {
        for (final entry in value.entries) {
          references(entry.key, into);
          references(entry.value, into);
        }
      } else if (value is List && value is! Uint8List) {
        for (final item in value) {
          references(item, into);
        }
      }
    }

    final owned = <String>{}, retained = <String>{};
    for (final value in removal.values) {
      references(value, owned);
    }
    // Navigation preferences are transient IDs, not durable photo ownership.
    // Include all remaining project/room/design records, even archived/deleted ones.
    for (final key in records.keys.whereType<String>()) {
      if (!removal.containsKey(key) &&
          (key.startsWith('project:') ||
              key.startsWith('room:') ||
              key.startsWith('design:'))) {
        references(records.get(key), retained);
      }
    }
    final images = <String, dynamic>{
      for (final id in owned.difference(retained)) id: photos.get(id),
    };
    final size = images.values.fold<int>(
      0,
      (sum, value) => sum + (value is List<int> ? value.length : 0),
    );
    final revision = sha256
        .convert(
          utf8.encode(
            jsonEncode({
              'records': removal,
              'images': {
                for (final entry in images.entries)
                  entry.key: entry.value is List<int>
                      ? (entry.value as List<int>).length
                      : null,
              },
            }),
          ),
        )
        .toString();
    return ArchiveRemovalPlan._(
      project,
      Map.unmodifiable(removal),
      Map.unmodifiable(images),
      roomIds.length,
      designCount,
      size,
      revision,
    );
  }
}
