// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';
import 'dart:io';
import 'package:socket_trace/socket_trace.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run trace_client.dart <VM_SERVICE_URL>');
    print(
      'Example: dart run trace_client.dart http://127.0.0.1:56789/auth-code/',
    );
    return;
  }

  final tracer = VMTraceClient(Uri.parse(args[0]));

  print('\x1B[36mConnecting to VM Service...\x1B[0m');

  try {
    await tracer.startTracing();
  } catch (e) {
    print('\x1B[31mFailed to connect: $e\x1B[0m');
    return;
  }

  print('\x1B[32mConnected! Listening for WebSocket frames...\x1B[0m\n');
  print('┌───────────────┬───────────┬──────────┬─────────┐');
  print('│ Time          │ Direction │ Type     │ Size    │');
  print('├───────────────┼───────────┼──────────┼─────────┤');

  // Keep the process alive
  ProcessSignal.sigint.watch().listen((_) async {
    print('\n\x1B[33mStopping trace...\x1B[0m');
    await tracer.dispose();
    exit(0);
  });

  await Completer().future;
}
