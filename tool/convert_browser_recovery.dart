import 'dart:convert';
import 'dart:io';

import 'recover_browser_projects.dart'
    show backupsFromBrowserDump, decodeBrowserValue;

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw ArgumentError('Pass the private browser-dump.json path.');
  }
  final source = File(arguments.single).absolute;
  final dump = jsonDecode(await source.readAsString()) as Map<String, dynamic>;
  final records = (dump['records'] as Map).map(
    (key, value) => MapEntry(key, decodeBrowserValue(value)),
  );
  final report = {
    'projects': [
      for (final entry in records.entries.where(
        (e) => (e.key as String).startsWith('project:'),
      ))
        entry.value,
    ],
    'rooms': [
      for (final entry in records.entries.where(
        (e) => (e.key as String).startsWith('room:'),
      ))
        entry.value,
    ],
    'designs': [
      for (final entry in records.entries.where(
        (e) => (e.key as String).startsWith('design:'),
      ))
        entry.value,
    ],
  };
  await File('${source.parent.path}/project-records.private.json')
      .writeAsString(jsonEncode(report), flush: true);
  final backups = backupsFromBrowserDump(dump);
  for (final (index, backup) in backups.indexed) {
    final destination = File(
      '${source.parent.path}/recovered-project-${index + 1}.renovision.json',
    );
    if (await destination.exists()) {
      throw StateError(
        'Existing recovery export retained; choose another copy deliberately.',
      );
    }
    final bytes = backup.encode();
    await destination.writeAsBytes(bytes, flush: true);
    stdout.writeln(
      'Validated recovery: ${destination.path}; ${backup.rooms.length} rooms, ${backup.designs.length} designs, ${backup.photos.length} images; ${bytes.length} bytes. Original browser and raw copy unchanged.',
    );
  }
}
