// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';
import 'dart:io';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';
import 'package:intl/intl.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run trace_client.dart <VM_SERVICE_URL>');
    print('Example: dart run trace_client.dart http://127.0.0.1:56789/auth-code/');
    return;
  }

  var serviceUrl = args[0];
  if (!serviceUrl.endsWith('/')) serviceUrl += '/';
  
  final wsUrl = serviceUrl.startsWith('http')
      ? serviceUrl.replaceFirst('http', 'ws') + 'ws'
      : serviceUrl;

  print('\x1B[36mConnecting to VM Service at $wsUrl...\x1B[0m');
  
  VmService service;
  try {
    service = await vmServiceConnectUri(wsUrl);
  } catch (e) {
    print('\x1B[31mFailed to connect: $e\x1B[0m');
    return;
  }

  print('\x1B[32mConnected! Enabling timeline for WebSocket events...\x1B[0m');
  
  // Custom events from Timeline.instantSync appear in the 'Dart' category
  await service.setVMTimelineFlags(['Dart']);

  print('\n\x1B[1mListening for WebSocket frames...\x1B[0m\n');
  print('┌───────────────┬───────────┬──────────┬─────────┐');
  print('│ Time          │ Direction │ Type     │ Size    │');
  print('├───────────────┼───────────┼──────────┼─────────┤');

  final dateFormat = DateFormat('HH:mm:ss.SSS');

  service.onTimelineEvent.listen((Event event) {
    final timelineEvent = event.timelineEvent;
    if (timelineEvent == null) return;
    
    // Timeline.instantSync events are usually under 'Dart' and have the name we gave it.
    final name = timelineEvent.json?['name'];
    if (name == 'WebSocketFrame') {
      final args = timelineEvent.json?['args'] as Map<String, dynamic>;
      final timestamp = timelineEvent.json?['ts'] as int;
      // TS is in microseconds since VM start. We can't easily get wall clock from it here without more sync,
      // so we use DateTime.now() as an approximation of arrival time or just relative.
      // But for better UX, we'll just use current time for the log.
      
      final timeStr = dateFormat.format(DateTime.now());
      final direction = (args['direction'] as String).toUpperCase();
      final type = (args['type'] as String).toUpperCase();
      final size = '${args['size']} B';

      final dirColor = direction == 'SEND' ? '\x1B[34m' : '\x1B[35m'; // Blue vs Magenta
      
      print('│ $timeStr  │ $dirColor${direction.padRight(9)}\x1B[0m │ ${type.padRight(8)} │ ${size.padRight(7)} │');
    }
  });

  await service.streamListen(EventStreams.kTimeline);

  // Keep the process alive
  ProcessSignal.sigint.watch().listen((_) async {
    print('\n\x1B[33mStopping trace...\x1B[0m');
    await service.dispose();
    exit(0);
  });

  await Completer().future;
}
