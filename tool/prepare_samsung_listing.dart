// Offline draft export. No app data, credentials, network, APK or publication.
// dart run tool/prepare_samsung_listing.dart
// Set RENOVISION_FFMPEG / RENOVISION_FFPROBE if FFmpeg is elsewhere.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:renovision_ai/app_brand.dart';

const _localBin =
    'output/dev-tools/ffmpeg/unpacked/ffmpeg-9.1-essentials_build/bin';

Future<String> _run(String program, List<String> arguments) async {
  final result = await Process.run(program, arguments);
  if (result.exitCode != 0) {
    throw StateError(
      '${File(program).uri.pathSegments.last}: ${result.stderr}',
    );
  }
  return result.stdout as String;
}

String _section(String guide, String id) {
  final start = '<!-- samsung-$id-copy:start -->';
  final end = '<!-- samsung-$id-copy:end -->';
  if (!guide.contains(start) || !guide.contains(end)) {
    throw StateError('Listing copy markers are missing.');
  }
  return guide.split(start).last.split(end).first.trim();
}

Future<void> main() async {
  final ffmpeg =
      Platform.environment['RENOVISION_FFMPEG'] ??
      (File('$_localBin/ffmpeg.exe').existsSync()
          ? '$_localBin/ffmpeg.exe'
          : 'ffmpeg');
  final ffprobe =
      Platform.environment['RENOVISION_FFPROBE'] ??
      (File('$_localBin/ffprobe.exe').existsSync()
          ? '$_localBin/ffprobe.exe'
          : 'ffprobe');
  await _run(ffmpeg, ['-version']);
  await _run(ffprobe, ['-version']);
  const font = 'C:/Windows/Fonts/segoeui.ttf';
  const bold = 'C:/Windows/Fonts/seguisb.ttf';
  if (!File(font).existsSync() || !File(bold).existsSync()) {
    throw StateError(
      'This draft renderer uses the existing Windows Segoe UI fonts.',
    );
  }
  final guide = (await File(
    'docs/GOOGLE_PLAY_RELEASE.md',
  ).readAsString()).replaceAll('\r\n', '\n');
  final copy = _section(guide, 'public');
  final short = copy.split('SHORT DESCRIPTION\n').last.split('\n').first;
  final title = copy.split('APP TITLE\n').last.split('\n').first;
  final full = copy.split('FULL DESCRIPTION\n').last;
  final review = _section(guide, 'review');
  if (utf8.encode(short).length > 40 ||
      utf8.encode(full).length > 4000 ||
      utf8.encode(review).length > 4000) {
    throw StateError('Draft exceeds Samsung metadata byte limits.');
  }
  final output = Directory(
    'output/samsung-listing-draft/draft-${DateTime.now().microsecondsSinceEpoch}',
  );
  await output.create(recursive: true);
  final work = await Directory('${output.path}/working').create();
  Future<void> text(String name, String content) =>
      File('${output.path}/$name').writeAsString('$content\n');
  await text('listing-copy.txt', copy);
  await text('reviewer-notes.txt', review);
  await text(
    'listing-fields.json',
    const JsonEncoder.withIndent('  ').convert({
      'submissionReady': false,
      'appTitle': title,
      'shortDescription': short,
      'longDescription': full,
      'defaultLanguageCode': 'ENG',
      'supportEMail': null,
      'privatePolicyURL': null,
      'reviewComment': review,
    }),
  );
  final icon = File('${output.path}/draft-icon-512.png');
  await File('macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png')
      .copy(icon.path);

  final shots = [
    ('01-room-photos', 'design', 4.6),
    ('02-design-direction', 'design', 8.3),
    ('03-refine', 'design', 31.6),
    ('04-compare', 'library', 17.5),
    ('05-save-project', 'saving', 3.0),
  ];
  for (final (name, clip, time) in shots) {
    await _run(ffmpeg, [
      '-hide_banner',
      '-loglevel',
      'error',
      '-n',
      '-ss',
      '$time',
      '-i',
      'assets/walkthroughs/$clip.mp4',
      '-frames:v',
      '1',
      '-update',
      '1',
      '${output.path}/draft-$name.png',
    ]);
  }

  final scenes = [
    (
      source: 'assets/demo/before.jpg',
      photo: true,
      start: 0,
      seconds: 4,
      heading: 'Start with your\nreal space.',
      body: 'Your own photos.\nYour renovation ideas.',
    ),
    (
      source: 'assets/demo/concept.jpg',
      photo: true,
      start: 0,
      seconds: 4,
      heading: 'Explore a\ndifferent look.',
      body: 'Compare ideas before\nmaking real changes.',
    ),
    (
      source: 'assets/walkthroughs/design.mp4',
      photo: false,
      start: 6,
      seconds: 8,
      heading: 'Choose your\ndirection.',
      body: 'Set your renovation goal\nand review the design plan.',
    ),
    (
      source: 'assets/walkthroughs/library.mp4',
      photo: false,
      start: 11,
      seconds: 7,
      heading: 'Compare.\nKeep. Refine.',
      body: 'Revisit saved designs\nand compare the original.',
    ),
    (
      source: 'assets/walkthroughs/saving.mp4',
      photo: false,
      start: 2,
      seconds: 5,
      heading: 'Keep your\nproject together.',
      body: 'Save a project file.\nKeep your rooms and versions.',
    ),
    (
      source: 'assets/demo/concept.jpg',
      photo: true,
      start: 0,
      seconds: 4,
      heading: appTagline.replaceFirst('Imagine. ', 'Imagine.\n'),
      body:
          '${appDescription.replaceFirst('. ', '.\n')}\n\n'
          'Bring your own AI key.\nProvider usage costs extra.',
    ),
  ];
  final storyboard = StringBuffer(
    '$appName - DRAFT ONLY: final phone recording/release acceptance pending.\n'
    '32-second silent concept trailer; no music, voice or live AI call.\n'
    'Kitchen result is a historical externally generated example; not a timed in-app result.\n'
    'UI excerpts are existing Help recordings with simulated AI/camera/file chooser.\n\n',
  );
  var elapsed = 0;
  final segments = <String>[];
  String draw(
    String file,
    String fontPath,
    int size,
    String colour,
    int x,
    int y,
  ) =>
      "drawtext=fontfile='${fontPath.replaceAll(':', r'\:')}':textfile='$file':"
      'fontsize=$size:fontcolor=$colour:x=$x:y=$y:line_spacing=10';
  for (final (index, scene) in scenes.indexed) {
    stdout.writeln('Rendering draft scene ${index + 1}/${scenes.length}');
    final heading = '${work.path}/heading-$index.txt';
    final body = '${work.path}/body-$index.txt';
    final label = '${work.path}/label-$index.txt';
    await File(heading).writeAsString(scene.heading);
    await File(body).writeAsString(scene.body);
    await File(label).writeAsString(
      scene.photo
          ? 'DRAFT SAMPLE  |  Historical external AI example  |  $appName'
          : 'DRAFT SAMPLE  |  Recorded app UI; AI / camera / file picker simulated',
    );
    final eyebrow = '${work.path}/eyebrow.txt';
    await File(eyebrow).writeAsString(appName);
    final panel = scene.photo
        ? '[0:v]scale=700:520:force_original_aspect_ratio=decrease,pad=720:540:(ow-iw)/2:(oh-ih)/2:color=0xF1ECE3[panel];'
        : '[0:v]scale=300:600[panel];';
    final overlay = scene.photo
        ? 'overlay=520:90:shortest=1'
        : 'overlay=860:48:shortest=1';
    final filter =
        '$panel[1:v][panel]$overlay,'
        '${draw(eyebrow, bold, 17, '0x706B3E', 56, 76)},'
        '${draw(heading, bold, scene.photo ? 43 : 52, '0x292A24', 56, 185)},'
        '${draw(body, font, scene.photo ? 23 : 26, '0x50524A', 58, 365)},'
        'drawbox=x=56:y=552:w=120:h=5:color=0x706B3E:t=fill,'
        '${draw(label, font, 17, '0x50524A', 56, 676)},format=yuv420p[out]';
    final segment = '${work.path}/scene-$index.mp4';
    await _run(ffmpeg, [
      '-hide_banner',
      '-loglevel',
      'error',
      '-n',
      if (scene.photo) ...[
        '-loop',
        '1',
        '-framerate',
        '24',
      ] else ...[
        '-ss',
        '${scene.start}',
      ],
      '-i',
      scene.source,
      '-f',
      'lavfi',
      '-i',
      'color=c=0xF1ECE3:s=1280x720:r=24',
      '-filter_complex',
      filter,
      '-map',
      '[out]',
      '-t',
      '${scene.seconds}',
      '-r',
      '24',
      '-an',
      '-c:v',
      'libx264',
      '-preset',
      'fast',
      '-crf',
      '21',
      '-profile:v',
      'baseline',
      '-level',
      '3.1',
      '-pix_fmt',
      'yuv420p',
      segment,
    ]);
    segments.add('file scene-$index.mp4');
    storyboard.writeln(
      '$elapsed-${elapsed + scene.seconds}s: ${scene.heading.replaceAll('\n', ' ')}\n'
      '${scene.body.replaceAll('\n', ' ')}\nSource: ${scene.source}; excerpt starts ${scene.start}s.\n',
    );
    elapsed += scene.seconds;
  }
  await File('${work.path}/segments.ffconcat')
      .writeAsString('ffconcat version 1.0\n${segments.join('\n')}\n');
  final trailer = File('${output.path}/promo-draft.mp4');
  await _run(ffmpeg, [
    '-hide_banner',
    '-loglevel',
    'error',
    '-n',
    '-f',
    'concat',
    '-safe',
    '1',
    '-i',
    '${work.path}/segments.ffconcat',
    '-c',
    'copy',
    '-movflags',
    '+faststart',
    trailer.path,
  ]);
  await text('demo-storyboard.txt', storyboard.toString());
  final probe = jsonDecode(
    await _run(ffprobe, [
      '-v',
      'error',
      '-show_entries',
      'format=duration:stream=codec_name,width,height,pix_fmt',
      '-of',
      'json',
      trailer.path,
    ]),
  ) as Map;
  final stream = (probe['streams'] as List).single as Map;
  final duration = double.parse((probe['format'] as Map)['duration'] as String);
  if (stream['codec_name'] != 'h264' ||
      stream['width'] != 1280 ||
      stream['height'] != 720 ||
      (duration - 32).abs() > 0.15) {
    throw StateError('Trailer validation failed: $probe');
  }
  final assets = <String, Object?>{};
  for (final file in output.listSync().whereType<File>()) {
    assets[file.uri.pathSegments.last] = {
      'bytes': await file.length(),
      'sha256': sha256.convert(await file.readAsBytes()).toString(),
    };
  }
  await text(
    'asset-manifest.json',
    const JsonEncoder.withIndent('  ').convert({
      'status': 'draft-not-for-upload',
      'preparedForDate': '28 November 2026, Australia/Sydney',
      'appName': appName,
      'liveAiUsed': false,
      'submitted': false,
      'sources': [
        'assets/demo/flow.json',
        'assets/walkthroughs/recordings.json',
      ],
      'shortDescriptionBytes': utf8.encode(short).length,
      'fullDescriptionBytes': utf8.encode(full).length,
      'reviewCommentBytes': utf8.encode(review).length,
      'video': probe,
      'files': assets,
    }),
  );
  stdout.writeln('Draft pack: ${output.path}');
  stdout.writeln(
    'No upload, account, app data, paid AI request or APK involved.',
  );
}
