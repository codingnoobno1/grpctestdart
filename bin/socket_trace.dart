// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:io';
import 'package:socket_trace/socket_trace.dart';

void main(List<String> args) async {
  int port = 4000;
  
  if (args.contains('--help') || args.contains('-h')) {
    print('Usage: dart run socket_trace [port]');
    print('Default port is 4000');
    return;
  }

  if (args.isNotEmpty) {
    final parsedPort = int.tryParse(args[0]);
    if (parsedPort != null) {
      port = parsedPort;
    }
  }

  print('🚀 Starting Socket Trace Debug Server...');
  final started = await EmbeddedDebugServer.start(port: port);
  
  if (started) {
    print('✅ Server is live at http://localhost:$port');
    print('CTRL+C to stop');
  } else {
    print('❌ Failed to start server on port $port');
    exit(1);
  }
}
