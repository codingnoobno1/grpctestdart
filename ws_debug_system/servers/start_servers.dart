import 'dart:io';

Future<void> main() async {
  print('--- Starting Dual WebSocket Servers ---');
  
  final processes = <Process>[];

  // Start Server 1
  print('Starting WS Server 1 (8081)...');
  final p1 = await Process.start('dart', ['ws_server_1.dart']);
  p1.stdout.transform(SystemEncoding().decoder).listen((data) => stdout.write('[Node 1] $data'));
  p1.stderr.transform(SystemEncoding().decoder).listen((data) => stderr.write('[Node 1] ERR: $data'));
  processes.add(p1);

  // Start Server 2
  print('Starting WS Server 2 (8082)...');
  final p2 = await Process.start('dart', ['ws_server_2.dart']);
  p2.stdout.transform(SystemEncoding().decoder).listen((data) => stdout.write('[Node 2] $data'));
  p2.stderr.transform(SystemEncoding().decoder).listen((data) => stderr.write('[Node 2] ERR: $data'));
  processes.add(p2);

  print('Servers are up. Press Ctrl+C to stop.');

  ProcessSignal.sigint.watch().listen((_) {
    print('\nShutting down...');
    for (var p in processes) {
      p.kill();
    }
    exit(0);
  });
}
