// Serve the compiled JS on localhost in an isolated Chrome profile only.
// Phase write saves synthetic provider fixtures; phase read runs after reload.

import 'package:web/web.dart' as web;
import 'package:renovision_ai/secret_store_web.dart';

Future<void> main() async {
  try {
    final openai = BrowserSecretStore('openai'),
        gemini = BrowserSecretStore('gemini');
    if (web.URL(web.window.location.href).searchParams.get('phase') == 'read') {
      if (await openai.read() != 'synthetic-openai-restart-fixture' ||
          await gemini.read() != 'synthetic-gemini-restart-fixture') {
        throw StateError('Provider keys did not survive reload');
      }
      await openai.delete();
      if (await openai.read() != null ||
          await gemini.read() != 'synthetic-gemini-restart-fixture') {
        throw StateError('Removing one provider affected the other');
      }
      await gemini.delete();
      web.document.body!.textContent = 'PASS: encrypted provider fixtures survive reload; separate removal works.';
    } else {
      await openai.write('synthetic-openai-restart-fixture');
      await gemini.write('synthetic-gemini-restart-fixture');
      if (await openai.read() != 'synthetic-openai-restart-fixture') {
        throw StateError('Round-trip failed');
      }
      web.document.body!.textContent = 'PASS: synthetic provider fixtures encrypted and saved; reload for read phase.';
    }
    web.document.body!.setAttribute('data-secret-check', 'passed');
  } catch (error) {
    web.document.body!.textContent = 'FAIL: $error';
    web.document.body!.setAttribute('data-secret-check', 'failed');
  }
}
