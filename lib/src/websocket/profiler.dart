// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:io';
import 'websocket_instrumentation.dart';

/// Helper class for managing profiled WebSocket connections.
class WebSocketProfiler {
  /// Connects to a WebSocket and returns a [ProfileableWebSocket] wrapper.
  static Future<ProfileableWebSocket> connect(
    String url, {
    Iterable<String>? protocols,
    Map<String, dynamic>? headers,
    CompressionOptions compression = CompressionOptions.compressionDefault,
  }) async {
    final socket = await WebSocket.connect(
      url,
      protocols: protocols,
      headers: headers,
      compression: compression,
    );
    return ProfileableWebSocket(socket);
  }
}
