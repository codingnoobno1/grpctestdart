import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:devtools_shared/devtools_shared.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WebSocketProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dual-WS Node Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00E5FF), // Neon Cyan
        scaffoldBackgroundColor: const Color(0xFF0A0F1E),
        cardColor: const Color(0xFF161B33),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const DashboardScreen(),
    );
  }
}

class LogEntry {
  final String node;
  final String message;
  final DateTime timestamp;
  final Color color;

  LogEntry(this.node, this.message, this.timestamp, this.color);
}

class WebSocketProvider with ChangeNotifier {
  WebSocketChannel? _node1;
  WebSocketChannel? _node2;
  
  bool isConnected1 = false;
  bool isConnected2 = false;

  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => List.unmodifiable(_logs);

  void connectAll() {
    unawaited(_connectNode1());
    unawaited(_connectNode2());
  }

  String get _host => Platform.isAndroid ? '10.0.2.2' : 'localhost';

  Future<void> _connectNode1() async {
    try {
      final socket = await WebSocket.connect('ws://$_host:8081');
      _node1 = IOWebSocketChannel(ProfileableWebSocket(socket));
      isConnected1 = true;
      _addLog('SYSTEM', 'Connecting to Node 1 ($_host)...', Colors.grey);
      
      _node1!.stream.listen((msg) {
        _addLog('NODE 1', msg.toString(), const Color(0xFF00E5FF));
      }, onDone: () {
        isConnected1 = false;
        _addLog('SYSTEM', 'Node 1 Disconnected', Colors.redAccent);
        notifyListeners();
      }, onError: (e) {
        isConnected1 = false;
        _addLog('ERROR', 'Node 1 Error: $e', Colors.redAccent);
        notifyListeners();
      });
      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Failed to connect Node 1: $e', Colors.redAccent);
    }
  }

  Future<void> _connectNode2() async {
    try {
      final socket = await WebSocket.connect('ws://$_host:8082');
      _node2 = IOWebSocketChannel(ProfileableWebSocket(socket));
      isConnected2 = true;
      _addLog('SYSTEM', 'Connecting to Node 2 ($_host)...', Colors.grey);
      
      _node2!.stream.listen((msg) {
        _addLog('NODE 2', msg.toString(), const Color(0xFFD500F9)); // Neon Purple
      }, onDone: () {
        isConnected2 = false;
        _addLog('SYSTEM', 'Node 2 Disconnected', Colors.redAccent);
        notifyListeners();
      }, onError: (e) {
        isConnected2 = false;
        _addLog('ERROR', 'Node 2 Error: $e', Colors.redAccent);
        notifyListeners();
      });
      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Failed to connect Node 2: $e', Colors.redAccent);
    }
  }

  void sendToNode1(String payload) {
    if (isConnected1 && _node1 != null) {
      final msg = jsonEncode({'type': 'DATA', 'payload': payload});
      _node1!.sink.add(msg);
      _addLog('TX -> N1', payload, const Color(0xFF00E5FF).withOpacity(0.7));
    }
  }

  void sendToNode2(String payload) {
    if (isConnected2 && _node2 != null) {
      final msg = jsonEncode({'type': 'DATA', 'payload': payload});
      _node2!.sink.add(msg);
      _addLog('TX -> N2', payload, const Color(0xFFD500F9).withOpacity(0.7));
    }
  }

  void _addLog(String node, String message, Color color) {
    _logs.insert(0, LogEntry(node, message, DateTime.now(), color));
    if (_logs.length > 100) _logs.removeLast();
    notifyListeners();
  }

  @override
  void dispose() {
    _node1?.sink.close();
    _node2?.sink.close();
    super.dispose();
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WebSocketProvider>().connectAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wsProvider = context.watch<WebSocketProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Node Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => wsProvider.connectAll(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Header
            Row(
              children: [
                _buildStatusChip('NODE 1 [ECHO]', wsProvider.isConnected1, const Color(0xFF00E5FF)),
                const SizedBox(width: 12),
                _buildStatusChip('NODE 2 [RELAY]', wsProvider.isConnected2, const Color(0xFFD500F9)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Control Panel
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Enter mission data/knowledge packet...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.black12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => wsProvider.sendToNode1(_controller.text),
                            icon: const Icon(Icons.send),
                            label: const Text('Send to Node 1'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF),
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => wsProvider.sendToNode2(_controller.text),
                            icon: const Icon(Icons.hub),
                            label: const Text('Broadcast via Node 2'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD500F9),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Log Terminal
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('LOG TERMINAL', style: TextStyle(letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: wsProvider.logs.length,
                  itemBuilder: (context, index) {
                    final log = wsProvider.logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('HH:mm:ss').format(log.timestamp),
                            style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: log.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: log.color.withOpacity(0.3)),
                            ),
                            child: Text(
                              log.node,
                              style: TextStyle(color: log.color, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log.message,
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isOnline, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? color.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOnline ? color.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? color : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                if (isOnline) BoxShadow(color: color.withOpacity(0.5), blurRadius: 4, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
