// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';
import 'package:intl/intl.dart';

/// Callback for captured WebSocket frames.
typedef FrameCallback =
    void Function({
      required DateTime time,
      required String direction,
      required String type,
      required int size,
    });

/// A client for tracing WebSocket frames via the Dart VM Service.
class VMTraceClient {
  VMTraceClient(this.vmServiceUri);

  final Uri vmServiceUri;
  VmService? _service;
  final DateFormat _dateFormat = DateFormat('HH:mm:ss.SSS');

  /// Starts tracing WebSocket frames.
  Future<void> startTracing({FrameCallback? onFrame}) async {
    var wsUrl = vmServiceUri.toString();
    if (!wsUrl.endsWith('/')) wsUrl += '/';

    final finalWsUrl = wsUrl.startsWith('http')
        ? wsUrl.replaceFirst('http', 'ws') + 'ws'
        : wsUrl;

    _service = await vmServiceConnectUri(finalWsUrl);

    // Custom events from Timeline.instantSync appear in the 'Dart' category
    await _service!.setVMTimelineFlags(['Dart']);

    _service!.onTimelineEvent.listen((Event event) {
      final timelineEvents = event.timelineEvents;
      if (timelineEvents == null || timelineEvents.isEmpty) return;

      for (final timelineEvent in timelineEvents) {
        final name = timelineEvent.json?['name'];
        if (name == 'WebSocketFrame') {
          final args = timelineEvent.json?['args'] as Map<String, dynamic>;

          if (onFrame != null) {
            onFrame(
              time: DateTime.now(),
              direction: (args['direction'] as String).toUpperCase(),
              type: (args['type'] as String).toUpperCase(),
              size: args['size'] as int,
            );
          } else {
            _defaultPrint(
              time: DateTime.now(),
              direction: (args['direction'] as String).toUpperCase(),
              type: (args['type'] as String).toUpperCase(),
              size: args['size'] as int,
            );
          }
        }
      }
    });

    await _service!.streamListen(EventStreams.kTimeline);
  }

  void _defaultPrint({
    required DateTime time,
    required String direction,
    required String type,
    required int size,
  }) {
    final timeStr = _dateFormat.format(time);
    final sizeStr = '$size B';
    final dirColor = direction == 'SEND'
        ? '\x1B[34m'
        : '\x1B[35m'; // Blue vs Magenta

    print(
      '│ $timeStr  │ $dirColor${direction.padRight(9)}\x1B[0m │ ${type.padRight(8)} │ ${sizeStr.padRight(7)} │',
    );
  }

  /// Disposes of the VM service connection.
  Future<void> dispose() async {
    await _service?.dispose();
    _service = null;
  }
}
