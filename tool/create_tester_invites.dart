import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'tester_gateway.dart' show invitationHash;

void main() {
  final folder = Directory('output/private-tester-service');
  folder.createSync(recursive: true);
  final ledger = File('${folder.path}/tester-ledger.local.json');
  final invitations = File('${folder.path}/invitations.local.json');
  if (ledger.existsSync() || invitations.existsSync()) {
    throw StateError(
      'Existing invitations retained. Choose a fresh directory or manage the existing ledger deliberately.',
    );
  }
  final random = Random.secure();
  final expiry = DateTime.now()
      .toUtc()
      .add(const Duration(days: 30))
      .toIso8601String();
  final people = <String, dynamic>{}, codes = <Map<String, dynamic>>[];
  for (var n = 1; n <= 12; n++) {
    final token = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    people[invitationHash(token)] = {
      'analyses': 2,
      'designs': 3,
      'expires': expiry,
      'revoked': false,
    };
    codes.add({'tester': n, 'invitation': token});
  }
  ledger.writeAsStringSync(
    jsonEncode({
      'version': 1,
      'analyses': 24,
      'designs': 36,
      'testers': people,
      'attempted': {},
    }),
    flush: true,
  );
  invitations.writeAsStringSync(jsonEncode(codes), flush: true);
  stdout.writeln(
    'Private example files saved under output/private-tester-service. Do not commit or distribute the ledger/provider key. No service activated and no AI requests sent. Review counts, expiry, model and budget before use.',
  );
}
