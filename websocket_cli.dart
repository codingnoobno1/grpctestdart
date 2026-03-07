// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';
import 'package:socket_trace/socket_trace.dart';

void main() async {
  final url = 'ws://localhost:8081';
  print('Connecting to $url...');

  ProfileableWebSocket socket;
  try {
    socket = await WebSocketProfiler.connect(url);
  } catch (e) {
    print('Failed to connect to $url. Make sure the server is running.');
    return;
  }

  print('Connected! Sending messages...');

  // Send some messages
  socket.add('Hello Server!');
  await Future.delayed(Duration(milliseconds: 500));
  socket.add('Ping');
  await Future.delayed(Duration(milliseconds: 500));
  socket.addUtf8Text('UTF8 Message'.codeUnits);

  // Listen for responses
  final subscription = socket.listen((data) {
    print('Received: $data');
  });

  // Wait for some data to be recorded
  await Future.delayed(Duration(seconds: 2));

  print('\nCaptured WebSocket Events:');
  print('┌───────────────┬───────────┬─────────┐');
  print('│ Time          │ Direction │ Size    │');
  print('├───────────────┼───────────┼─────────┤');

  for (final event in socket.buffer) {
    final timeStr = event.time.toIso8601String().split('T')[1].substring(0, 12);
    final directionStr = event.direction.toUpperCase().padRight(9);
    final sizeStr = '${event.size} B'.padRight(7);
    print('│ $timeStr  │ $directionStr │ $sizeStr │');
  }

  print('└───────────────┴───────────┴─────────┘');

  await subscription.cancel();
  await socket.close();
  print('Socket closed.');
}
