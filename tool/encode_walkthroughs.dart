// Encode captured app transactions as standard, seekable Android/web MP4s.
// FFmpeg and ffprobe are development tools only, never bundled in the app.
import 'dart:convert';
import 'dart:io';

const clips = [
  'design',
  'capture',
  'live',
  'paint',
  'library',
  'saving',
  'models',
];

Future<String> run(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    throw StateError(
      '$executable failed (${result.exitCode}): ${result.stderr}',
    );
  }
  return result.stdout as String;
}

Future<void> main(List<String> arguments) async {
  final selected = arguments.isEmpty ? clips : arguments;
  if (selected.toSet().length != selected.length ||
      selected.any((id) => !clips.contains(id))) {
    throw ArgumentError('Choose valid recording IDs.');
  }
  final ffmpeg = Platform.environment['RENOVISION_FFMPEG'] ?? 'ffmpeg';
  final ffprobe = Platform.environment['RENOVISION_FFPROBE'] ?? 'ffprobe';
  try {
    await run(ffmpeg, ['-version']);
    await run(ffprobe, ['-version']);
  } on ProcessException {
    throw StateError(
      'Install FFmpeg/ffprobe or set RENOVISION_FFMPEG and RENOVISION_FFPROBE to their executable paths. No assets were changed.',
    );
  }
  final root = Directory.current;
  final raw = Directory('${root.path}/output/walkthrough-recording');
  final staged = await Directory('${root.path}/output/walkthrough-standard')
      .create(recursive: true);
  final destination = Directory('${root.path}/assets/walkthroughs');
  final catalog = File('${destination.path}/recordings.json');
  final old = await catalog.exists()
      ? jsonDecode(await catalog.readAsString()) as Map
      : <String, dynamic>{};
  if (old['encoding'] != 'h264-baseline-cfr' &&
      selected.length != clips.length) {
    throw StateError(
      'Encode all clips once before updating individual standard MP4s.',
    );
  }
  final results = <String, Map<String, dynamic>>{};
  for (final id in selected) {
    final manifest = jsonDecode(
      await File('${raw.path}/$id/frames.json').readAsString(),
    ) as Map;
    final frames = manifest['frames'] as List;
    if (manifest['id'] != id || frames.length < 4) {
      throw StateError('Incomplete recording $id');
    }
    final concat = StringBuffer('ffconcat version 1.0\n');
    var totalMs = 0;
    for (final frame in frames) {
      final name = frame['file'] as String;
      final ms = frame['ms'];
      if (!RegExp('^$id/[0-9]{4}[.]png\$').hasMatch(name) ||
          ms is! int ||
          ms < 1 ||
          ms > 30000 ||
          !await File('${raw.path}/$name').exists()) {
        throw StateError('Invalid recorded frame in $id');
      }
      totalMs += ms;
      concat.writeln("file '$name'");
      concat.writeln('duration ${(ms / 1000).toStringAsFixed(3)}');
    }
    // Repeating the final image lets concat honour its full hold duration.
    concat.writeln("file '${frames.last['file']}'");
    final listing = File('${raw.path}/$id.ffconcat');
    await listing.writeAsString(concat.toString());
    final output = File('${staged.path}/$id.mp4');
    stdout.writeln('Encoding $id: ${frames.length} frames, ${totalMs}ms');
    await run(ffmpeg, [
      '-hide_banner',
      '-loglevel',
      'error',
      '-y',
      '-f',
      'concat',
      '-safe',
      '1',
      '-i',
      listing.path,
      '-vf',
      'fps=10,setpts=PTS-STARTPTS,format=yuv420p',
      '-t',
      (totalMs / 1000).toStringAsFixed(3),
      '-an',
      '-c:v',
      'libx264',
      '-preset',
      'veryfast',
      '-crf',
      '20',
      '-profile:v',
      'baseline',
      '-level:v',
      '3.1',
      '-g',
      '20',
      '-video_track_timescale',
      '1000',
      '-movflags',
      '+faststart',
      '-map_metadata',
      '-1',
      '-map_chapters',
      '-1',
      output.path,
    ]);
    final probe = jsonDecode(
      await run(ffprobe, [
        '-v',
        'error',
        '-show_format',
        '-show_streams',
        '-of',
        'json',
        output.path,
      ]),
    ) as Map;
    final streams = probe['streams'] as List;
    if (streams.length != 1) {
      throw StateError('Expected a silent single video track.');
    }
    final video = streams.single as Map;
    final duration = double.parse(probe['format']['duration'] as String);
    if (video['codec_name'] != 'h264' ||
        video['pix_fmt'] != 'yuv420p' ||
        video['avg_frame_rate'] != '10/1' ||
        double.parse(video['start_time'] as String).abs() > .001 ||
        (duration - totalMs / 1000).abs() > .15) {
      throw StateError('Unexpected codec/timestamps/duration for $id');
    }
    await run(ffmpeg, ['-v', 'error', '-i', output.path, '-f', 'null', '-']);
    results[id] = {
      'id': id,
      'file': '$id.mp4',
      'durationMs': (duration * 1000).round(),
      'width': video['width'],
      'height': video['height'],
      'mime': 'video/mp4',
      'bytes': await output.length(),
    };
    stdout.writeln(
      'Verified $id: H.264 baseline, zero-based CFR timestamps, full decode, ${(duration * 1000).round()}ms.',
    );
  }
  // Publish only after all requested encodes pass validation.
  await destination.create(recursive: true);
  for (final id in selected) {
    await File('${staged.path}/$id.mp4').copy('${destination.path}/$id.mp4');
  }
  await catalog.writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'source': 'Recorded real app widgets with fictional photos, simulated AI/camera and disposable storage.',
      'encoding': 'h264-baseline-cfr',
      'recordings': {...?old['recordings'] as Map?, ...results},
    }),
  );
}
