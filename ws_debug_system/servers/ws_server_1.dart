import 'dart:convert';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

void main() async {
  final handler = webSocketHandler((webSocket) {
    print('[Server 1] Client connected');
    webSocket.stream.listen((message) {
      print('[Server 1] Received: $message');
      final messageText = message.toString();
      final response = jsonEncode({
        'node': 'SERVER_1',
        'type': 'ECHO',
        'payload': 'Echo: $messageText',
        'timestamp': DateTime.now().toIso8601String(),
      });
      webSocket.sink.add(response);
    }, onDone: () {
      print('[Server 1] Client disconnected');
    });
  });

  final server = await shelf_io.serve(handler, 'localhost', 8081);
  print('WebSocket Server 1 listening on ws://localhost:${server.port}');
}
