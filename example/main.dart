// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:flutter/material.dart';
import 'package:socket_trace/socket_trace.dart';

void main() {
  runApp(const SocketTraceExampleApp());
}

class SocketTraceExampleApp extends StatelessWidget {
  const SocketTraceExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Socket Trace Example',
      theme: ThemeData.dark(),
      home: const WebSocketDemo(),
    );
  }
}

class WebSocketDemo extends StatefulWidget {
  const WebSocketDemo({super.key});

  @override
  State<WebSocketDemo> createState() => _WebSocketDemoState();
}

class _WebSocketDemoState extends State<WebSocketDemo> {
  final List<SocketEvent> events = [];
  ProfileableWebSocket? socket;
  final TextEditingController _messageController = TextEditingController();
  bool isConnected = false;
  String statusMessage = 'Disconnected';

  Future<void> _connect() async {
    try {
      setState(() {
        statusMessage = 'Connecting...';
      });

      socket = await WebSocketProfiler.connect('wss://echo.websocket.org');

      socket!.listen(
        (message) {
          setState(() {
            events.addAll(socket!.buffer);
            statusMessage = 'Connected - Received: $message';
          });
        },
        onError: (error) {
          setState(() {
            statusMessage = 'Error: $error';
            isConnected = false;
          });
        },
        onDone: () {
          setState(() {
            statusMessage = 'Disconnected';
            isConnected = false;
          });
        },
      );

      setState(() {
        isConnected = true;
        statusMessage = 'Connected to echo.websocket.org';
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Connection failed: $e';
        isConnected = false;
      });
    }
  }

  void _sendMessage() {
    if (socket != null && isConnected) {
      final message = _messageController.text;
      if (message.isNotEmpty) {
        socket!.add(message);
        setState(() {
          events.addAll(socket!.buffer);
        });
        _messageController.clear();
      }
    }
  }

  Future<void> _disconnect() async {
    await socket?.close();
    setState(() {
      isConnected = false;
      statusMessage = 'Disconnected';
    });
  }

  void _clearEvents() {
    setState(() {
      events.clear();
      socket?.buffer.clear();
    });
  }

  @override
  void dispose() {
    _disconnect();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket Trace Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About'),
                  content: const Text(
                    'This example demonstrates the socket_trace package.\n\n'
                    '1. Connect to the WebSocket echo server\n'
                    '2. Send messages and see them echoed back\n'
                    '3. View all traffic in the trace view below',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.all(12),
            color: isConnected ? Colors.green.shade900 : Colors.red.shade900,
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Connection controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: isConnected ? null : _connect,
                  icon: const Icon(Icons.power),
                  label: const Text('Connect'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isConnected ? _disconnect : null,
                  icon: const Icon(Icons.power_off),
                  label: const Text('Disconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Message input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter message to send',
                      border: OutlineInputBorder(),
                    ),
                    enabled: isConnected,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isConnected ? _sendMessage : null,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Event statistics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCard(
                  label: 'Total Events',
                  value: events.length.toString(),
                  icon: Icons.list,
                ),
                _StatCard(
                  label: 'Sent',
                  value: events
                      .where((e) => e.direction == 'send')
                      .length
                      .toString(),
                  icon: Icons.arrow_upward,
                  color: Colors.blue,
                ),
                _StatCard(
                  label: 'Received',
                  value: events
                      .where((e) => e.direction == 'receive')
                      .length
                      .toString(),
                  icon: Icons.arrow_downward,
                  color: Colors.purple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Socket trace view
          Expanded(
            child: SocketTraceView(
              events: events,
              onClear: _clearEvents,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
