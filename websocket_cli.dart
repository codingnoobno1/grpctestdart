// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';
import 'dart:developer';
import 'dart:io';

/// Represents a single WebSocket frame event (send or receive).
class SocketEvent {
  SocketEvent({
    required this.time,
    required this.size,
    required this.type,
    required this.direction,
  });

  final DateTime time;
  final int size;
  final String type; // 'text' or 'binary'
  final String direction; // 'send' or 'receive'
}

/// A wrapper around [WebSocket] that instruments frame events.
class ProfileableWebSocket implements WebSocket {
  ProfileableWebSocket(this._socket);

  final WebSocket _socket;
  final List<SocketEvent> buffer = [];

  void _recordEvent(dynamic data, String direction, {bool isUtf8 = false}) {
    final size = (data is String)
        ? data.length
        : (data is List<int>)
            ? data.length
            : 0;
    final type = (data is String || isUtf8) ? 'text' : 'binary';
    final event = SocketEvent(
      time: DateTime.now(),
      size: size,
      type: type,
      direction: direction,
    );
    buffer.add(event);

    Timeline.instantSync(
      'WebSocketFrame',
      arguments: {
        'direction': direction,
        'size': size,
        'type': type,
      },
    );
  }

  @override
  void add(dynamic data) {
    _recordEvent(data, 'send');
    _socket.add(data);
  }

  @override
  void addUtf8Text(List<int> bytes) {
    _recordEvent(bytes, 'send', isUtf8: true);
    _socket.addUtf8Text(bytes);
  }

  @override
  StreamSubscription listen(
    void Function(dynamic)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _socket.listen(
      (data) {
        _recordEvent(data, 'receive');
        onData?.call(data);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<void> close([int? code, String? reason]) => _socket.close(code, reason);

  @override
  dynamic noSuchMethod(Invocation invocation) => _socket.noSuchMethod(invocation);
}

void main() async {
  final url = 'ws://localhost:8081';
  print('Connecting to $url...');

  WebSocket socket;
  try {
    socket = await WebSocket.connect(url);
  } catch (e) {
    print('Failed to connect to $url. Make sure the server is running.');
    return;
  }

  // Wrap the socket with ProfileableWebSocket
  final profileableSocket = ProfileableWebSocket(socket);

  print('Connected! Sending messages...');

  // Send some messages
  profileableSocket.add('Hello Server!');
  await Future.delayed(Duration(milliseconds: 500));
  profileableSocket.add('Ping');
  await Future.delayed(Duration(milliseconds: 500));
  profileableSocket.addUtf8Text('UTF8 Message'.codeUnits);

  // Listen for responses
  final subscription = profileableSocket.listen((data) {
    print('Received: $data');
  });

  // Wait for some data to be recorded
  await Future.delayed(Duration(seconds: 2));

  print('\nCaptured WebSocket Events:');
  print('┌───────────────┬─────────┬─────────┐');
  print('│ Time          │ Type    │ Size    │');
  print('├───────────────┼─────────┼─────────┤');

  for (final event in profileableSocket.buffer) {
    final timeStr = event.time.toIso8601String().split('T')[1].substring(0, 12);
    final typeStr = event.direction.toUpperCase();
    final sizeStr = '${event.size} B'.padRight(7);
    print('│ $timeStr  │ ${typeStr.padRight(7)} │ $sizeStr │');
  }

  print('└───────────────┴─────────┴─────────┘');

  await subscription.cancel();
  await profileableSocket.close();
  print('Socket closed.');
}
