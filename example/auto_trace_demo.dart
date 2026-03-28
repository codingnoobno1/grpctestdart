// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';
import 'package:socket_trace/socket_trace.dart';

/// Demo of automatic WebSocket tracing
/// 
/// This example shows how to use the automatic tracing API:
/// 1. Enable automatic tracing with SocketTrace.enable()
/// 2. Optionally start embedded debug server
/// 3. Use SocketTrace.connect() instead of WebSocket.connect()
/// 
/// Run this example:
/// ```
/// dart run example/auto_trace_demo.dart
/// ```
/// 
/// Then open http://localhost:4000 in your browser to see live packets!
void main() async {
  print('🔍 Socket Trace - Automatic Tracing Demo\n');
  
  // Step 1: Enable automatic tracing
  print('Step 1: Enabling automatic tracing...');
  await SocketTrace.enable(
    enableDebugServer: true,
    debugServerUrl: 'ws://localhost:4000',
  );
  print('✓ Automatic tracing enabled\n');
  
  // Step 2: Start embedded debug server
  print('Step 2: Starting embedded debug server...');
  final started = await EmbeddedDebugServer.start(port: 4000);
  if (started) {
    print('✓ Debug server running on http://localhost:4000');
    print('  Open this URL in your browser to see live packets!\n');
  } else {
    print('⚠ Debug server failed to start\n');
  }
  
  // Step 3: Connect to WebSocket using automatic tracing
  print('Step 3: Connecting to echo.websocket.org...');
  final socket = await SocketTrace.connect('wss://echo.websocket.org');
  print('✓ Connected!\n');
  
  // Step 4: Send and receive messages
  print('Step 4: Sending test messages...');
  
  socket.listen(
    (message) {
      print('📥 Received: $message');
    },
    onDone: () {
      print('\n✓ Connection closed');
      print('\nDemo complete! Check http://localhost:4000 to see the captured traffic.');
      EmbeddedDebugServer.stop();
    },
    onError: (error) {
      print('❌ Error: $error');
    },
  );
  
  // Send some test messages
  await Future.delayed(Duration(seconds: 1));
  socket.add('Hello from automatic tracing!');
  print('📤 Sent: Hello from automatic tracing!');
  
  await Future.delayed(Duration(seconds: 1));
  socket.add('This is message #2');
  print('📤 Sent: This is message #2');
  
  await Future.delayed(Duration(seconds: 1));
  socket.add('Final message');
  print('📤 Sent: Final message');
  
  // Wait a bit then close
  await Future.delayed(Duration(seconds: 2));
  await socket.close();
  
  // Keep server running for a bit so user can view the dashboard
  print('\nKeeping debug server running for 30 seconds...');
  print('Visit http://localhost:4000 to see the captured traffic');
  await Future.delayed(Duration(seconds: 30));
  
  EmbeddedDebugServer.stop();
  print('\n✓ Demo complete!');
}
