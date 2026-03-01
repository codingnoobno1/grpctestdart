import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() async {
  print('Connecting to WebSocket server...');
  final socket = await WebSocket.connect('ws://127.0.0.1:8080');
  print('Connected!');

  socket.listen((message) {
    print('Server says: $message');
  });

  // Test 1: Simple message
  socket.add('Hello Server');

  // Test 2: JSON message
  await Future.delayed(Duration(seconds: 1));
  socket.add(jsonEncode({'type': 'chat', 'message': 'hello world'}));

  // Test 3: Binary message
  await Future.delayed(Duration(seconds: 1));
  socket.add([1, 2, 3, 4, 5]);

  // Test 4: Frame Cap (Send 1100 messages)
  print('Sending bulk messages to test frame cap...');
  for (int i = 0; i < 1100; i++) {
    socket.add('Bulk Message $i');
  }
  print('Bulk messages sent.');

  print('Waiting 10 minutes for inspection (Live Mode test)...');
  await Future.delayed(Duration(minutes: 10));
  print('Closing socket.');
  await socket.close();
}
