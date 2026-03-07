import 'package:flutter/material.dart';
import 'package:socket_trace/socket_trace.dart';

void main() {
  runApp(const TraceApp());
}

class TraceApp extends StatelessWidget {
  const TraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Socket Tracer',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFF0A0F1E),
        useMaterial3: true,
      ),
      home: const TraceHomeScreen(),
    );
  }
}

class TraceHomeScreen extends StatefulWidget {
  const TraceHomeScreen({super.key});

  @override
  State<TraceHomeScreen> createState() => _TraceHomeScreenState();
}

class _TraceHomeScreenState extends State<TraceHomeScreen> {
  final TextEditingController _uriController = TextEditingController();
  final List<SocketEvent> _events = [];
  VMTraceClient? _traceClient;
  bool _isTracing = false;

  void _toggleTracing() async {
    if (_isTracing) {
      await _traceClient?.dispose();
      setState(() {
        _isTracing = false;
      });
    } else {
      final uriStr = _uriController.text.trim();
      if (uriStr.isEmpty) return;

      final uri = Uri.tryParse(uriStr);
      if (uri == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid VM Service URI')));
        return;
      }

      _traceClient = VMTraceClient(uri);
      try {
        await _traceClient!.startTracing(
          onFrame:
              ({
                required DateTime time,
                required String direction,
                required String type,
                required int size,
              }) {
                setState(() {
                  _events.insert(
                    0,
                    SocketEvent(
                      time: time,
                      size: size,
                      type: type.toLowerCase(),
                      direction: direction.toLowerCase(),
                    ),
                  );
                  if (_events.length > 500) _events.removeLast();
                });
              },
        );
        setState(() {
          _isTracing = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket Tracer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _events.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _uriController,
                    decoration: const InputDecoration(
                      labelText: 'VM Service URI',
                      hintText: 'ws://localhost:8181/ws',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _toggleTracing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracing ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: Text(_isTracing ? 'STOP' : 'START'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: SocketTraceView(
                events: _events,
                onClear: () => setState(() => _events.clear()),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _traceClient?.dispose();
    _uriController.dispose();
    super.dispose();
  }
}
