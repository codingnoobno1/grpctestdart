// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

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

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'size': size,
    'type': type,
    'direction': direction,
  };
}
