// Local development tool: encode recorded app frames using Chrome's built-in
// recorder. No encoder download, external service, user profile or paid AI.
import 'dart:async';
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
const encoderHtml = r'''<!doctype html><meta charset="utf-8"><title>RenoVision demo encoder</title>
<canvas id="screen"></canvas><pre id="status"></pre><script>
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
function event(target,name,timeout=10000){return new Promise((resolve,reject)=>{
 const timer=setTimeout(()=>reject(Error(name+' timed out')),timeout);
 target.addEventListener(name,()=>{clearTimeout(timer);resolve()},{once:true});
 target.addEventListener('error',()=>{clearTimeout(timer);reject(Error(name+' failed'))},{once:true});
})}
async function image(file){const value=new Image();value.src='/frame/'+file;await value.decode();return value}
async function run(){
 const manifest=await (await fetch('/manifest')).json();
 const canvas=document.querySelector('canvas'), ctx=canvas.getContext('2d');
 const formats=['video/mp4;codecs=avc1.42001E','video/mp4','video/webm;codecs=vp8'];
 const supported=formats.filter(t=>MediaRecorder.isTypeSupported(t));
 await fetch('/status',{method:'POST',body:'Encoder formats: '+supported.join(', ')});
 if(!supported.some(t=>t.startsWith('video/mp4')))throw Error('This Chrome needs MP4 recording support.');
 for(const clip of manifest){
  await fetch('/status',{method:'POST',body:'Encoding '+clip.id+' ('+clip.frames.length+' app frames)'});
  const first=await image(clip.frames[0].file);canvas.width=first.width;canvas.height=first.height;
  ctx.drawImage(first,0,0);const stream=canvas.captureStream(10);
  const chunks=[];let recorder;
  for(const type of supported.filter(t=>t.startsWith('video/mp4'))){
   try{recorder=new MediaRecorder(stream,{mimeType:type,videoBitsPerSecond:800000});break}catch(e){}
  }
  if(!recorder)throw Error('MP4 encoder unavailable');
  recorder.ondataavailable=e=>{if(e.data.size)chunks.push(e.data)};
  const stopped=event(recorder,'stop',300000);recorder.start(1000);
  for(const frame of clip.frames){
   const bitmap=await image(frame.file), until=performance.now()+frame.ms;
   do{ctx.drawImage(bitmap,0,0);await sleep(Math.min(100,Math.max(1,until-performance.now())))}while(performance.now()<until);
  }
  recorder.stop();await stopped;stream.getTracks().forEach(t=>t.stop());
  const blob=new Blob(chunks,{type:'video/mp4'});
  const probe=document.createElement('video');probe.muted=true;probe.preload='auto';
  const url=URL.createObjectURL(blob);probe.src=url;
  await event(probe,'loadedmetadata');
  if(!Number.isFinite(probe.duration)||probe.duration<=0)throw Error('Recording has no seekable duration: '+clip.id);
  const expected=clip.frames.reduce((sum,f)=>sum+f.ms,0)/1000;
  if(probe.duration<expected*.8||probe.duration>expected*1.4)throw Error('Recording timing differs from captured workflow: '+clip.id+' '+probe.duration+' / '+expected);
  const seeked=event(probe,'seeked');probe.currentTime=Math.min(2,probe.duration/2);await seeked;
  await probe.play();await sleep(150);probe.pause();
  const meta={id:clip.id,file:clip.id+'.mp4',durationMs:Math.round(probe.duration*1000),
    width:probe.videoWidth,height:probe.videoHeight,mime:'video/mp4',bytes:blob.size};
  URL.revokeObjectURL(url);
  await fetch('/video?id='+clip.id,{method:'POST',headers:{'X-Recording-Metadata':JSON.stringify(meta)},body:blob});
 }
 await fetch('/done',{method:'POST'});
}
run().catch(async error=>{document.querySelector('pre').textContent=String(error.stack||error);
 await fetch('/error',{method:'POST',body:String(error.stack||error)})});
</script>''';

Future<void> main(List<String> arguments) async {
  final selected = arguments.isEmpty ? clips : arguments;
  if (selected.toSet().length != selected.length ||
      selected.any((id) => !clips.contains(id))) {
    throw ArgumentError('Choose valid recording IDs.');
  }
  final root = Directory.current;
  final raw = Directory('${root.path}/output/walkthrough-recording');
  final destination = Directory('${root.path}/assets/walkthroughs');
  final manifest = <Map<String, dynamic>>[];
  final allowedFrames = <String, File>{};
  for (final id in selected) {
    final clip = jsonDecode(
      await File('${raw.path}/$id/frames.json').readAsString(),
    ) as Map<String, dynamic>;
    if (clip['id'] != id || (clip['frames'] as List).length < 4) {
      throw StateError('Incomplete app recording $id');
    }
    for (final frame in clip['frames'] as List) {
      final name = frame['file'] as String;
      if (!RegExp(r'^[a-z]+/[0-9]{4}\.png$').hasMatch(name)) {
        throw StateError('Invalid frame path');
      }
      final file = File('${raw.path}/$name');
      if (!await file.exists()) throw StateError('Missing app frame $name');
      allowedFrames[name] = file;
    }
    manifest.add(clip);
  }
  await destination.create(recursive: true);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final finished = Completer<void>(), results = <Map<String, dynamic>>[];
  late final StreamSubscription<HttpRequest> subscription;
  subscription = server.listen((request) async {
    try {
      final path = request.uri.path;
      if (path == '/encode') {
        request.response.headers.contentType = ContentType.html;
        request.response.write(encoderHtml);
      } else if (path == '/manifest') {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(manifest));
      } else if (path.startsWith('/frame/')) {
        final file = allowedFrames[path.substring(7)];
        if (file == null) {
          request.response.statusCode = 404;
        } else {
          request.response.headers.contentType = ContentType('image', 'png');
          await request.response.addStream(file.openRead());
        }
      } else if (path == '/status') {
        stdout.writeln(await utf8.decoder.bind(request).join());
      } else if (path == '/video' && request.method == 'POST') {
        final id = request.uri.queryParameters['id'];
        if (!clips.contains(id)) throw StateError('Unknown recording');
        final meta = jsonDecode(
          request.headers.value('X-Recording-Metadata')!,
        ) as Map<String, dynamic>;
        if (meta['file'] != '$id.mp4' ||
            meta['durationMs'] is! int ||
            meta['durationMs'] <= 0) {
          throw StateError('Invalid recording metadata');
        }
        final sink = File('${destination.path}/$id.mp4').openWrite();
        await sink.addStream(request);
        await sink.close();
        results.add(meta);
        stdout.writeln(
          'Verified ${meta['file']}: ${meta['durationMs']} ms, ${meta['bytes']} bytes; metadata/seek/decode passed.',
        );
      } else if (path == '/done') {
        if (results.length != selected.length) {
          throw StateError('Not all app recordings completed');
        }
        final catalogFile = File('${destination.path}/recordings.json');
        final previous = await catalogFile.exists()
            ? (jsonDecode(await catalogFile.readAsString())
                      as Map)['recordings']
                  as Map
            : <String, dynamic>{};
        await catalogFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'source': 'Recorded real app widgets with fictional photos, simulated AI/camera and disposable storage.',
            'recordings': {
              ...previous,
              for (final result in results) result['id'] as String: result,
            },
          }),
        );
        if (!finished.isCompleted) finished.complete();
      } else if (path == '/error') {
        final error = await utf8.decoder.bind(request).join();
        if (!finished.isCompleted) finished.completeError(StateError(error));
      } else {
        request.response.statusCode = 404;
      }
      await request.response.close();
    } catch (error, stack) {
      request.response.statusCode = 500;
      await request.response.close();
      if (!finished.isCompleted) finished.completeError(error, stack);
    }
  });
  final profile = Directory('${root.path}/output/walkthrough-encoding-profile');
  final chrome = await Process.start(
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    [
      '--headless=new',
      '--no-first-run',
      '--disable-background-networking',
      '--disable-sync',
      '--autoplay-policy=no-user-gesture-required',
      '--user-data-dir=${profile.path}',
      'http://127.0.0.1:${server.port}/encode',
    ],
  );
  unawaited(chrome.stdout.drain<void>());
  unawaited(chrome.stderr.drain<void>());
  try {
    await finished.future.timeout(const Duration(minutes: 8));
  } finally {
    chrome.kill();
    await subscription.cancel();
    await server.close(force: true);
  }
}
