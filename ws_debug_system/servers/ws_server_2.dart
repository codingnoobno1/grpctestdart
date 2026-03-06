import 'dart:convert';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final List<WebSocketChannel> _clients = [];

void main() async {
  final handler = webSocketHandler((webSocket) {
    _clients.add(webSocket);
    print('[Server 2] Client connected. Total clients: ${_clients.length}');

    webSocket.stream.listen((message) {
      print('[Server 2] Broadcasting: $message');
      final data = jsonDecode(message as String);
      final broadcastMsg = jsonEncode({
        'node': 'SERVER_2',
        'type': 'BROADCAST',
        'payload': data['payload'],
        'timestamp': DateTime.now().toIso8601String(),
        'clientCount': _clients.length,
      });

      for (final client in _clients) {
        client.sink.add(broadcastMsg);
      }
    }, onDone: () {
      _clients.remove(webSocket);
      print('[Server 2] Client disconnected. Total clients: ${_clients.length}');
    });
  });

  final server = await shelf_io.serve(handler, 'localhost', 8082);
  print('WebSocket Server 2 listening on ws://localhost:${server.port}');
}
