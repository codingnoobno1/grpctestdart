// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../websocket/websocket_event.dart';

/// Global debug server connection
WebSocket? _debugSocket;
bool _debugEnabled = false;

/// Enable forwarding of socket events to a debug server
/// 
/// This allows real-time monitoring of all socket traffic via a web UI.
/// 
/// Example:
/// ```dart
/// await DebugForwarder.enable('ws://localhost:4000');
/// ```
class DebugForwarder {
  /// Enable debug forwarding to the specified server URL
  static Future<void> enable(String debugServerUrl) async {
    try {
      _debugSocket = await WebSocket.connect(debugServerUrl);
      _debugEnabled = true;
      print('✓ Socket trace debug forwarding enabled: $debugServerUrl');
    } catch (e) {
      print('⚠ Failed to connect to debug server: $e');
      _debugEnabled = false;
    }
  }

  /// Disable debug forwarding
  static Future<void> disable() async {
    await _debugSocket?.close();
    _debugSocket = null;
    _debugEnabled = false;
    print('✓ Socket trace debug forwarding disabled');
  }

  /// Check if debug forwarding is enabled
  static bool get isEnabled => _debugEnabled;

  /// Forward a socket event to the debug server
  /// 
  /// [event] - The socket event to forward
  /// [nodeId] - Optional identifier for the connection
  /// [payload] - Optional payload data to include
  static void forward(
    SocketEvent event, {
    String? nodeId,
    String? payload,
  }) {
    if (!_debugEnabled || _debugSocket == null) return;

    try {
      _debugSocket!.add(jsonEncode({
        'time': event.time.toIso8601String(),
        'direction': event.direction,
        'type': event.type,
        'size': event.size,
        'node': nodeId ?? 'default',
        'payload': payload ?? '',
      }));
    } catch (e) {
      print('⚠ Failed to forward event to debug server: $e');
    }
  }
}
