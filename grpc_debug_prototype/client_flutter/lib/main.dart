import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'generated/debug.pbgrpc.dart';
import 'grpc_debug_interceptor.dart';
import 'grpc_debug_overlay.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gRPC Debug Client',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ClientChannel _channel;
  late DebugServiceClient _client;
  String _userName = "Unknown";
  int _userAge = 0;
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _channel = ClientChannel(
      'localhost',
      port: 50051,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
      interceptors: [DebugInterceptor()],
    );
    _client = DebugServiceClient(_channel);
  }

  Future<void> _getUser() async {
    try {
      final response = await _client.getUser(UserRequest()..id = "123");
      setState(() {
        _userName = response.name;
        _userAge = response.age;
      });
    } catch (e) {
      print('Error calling GetUser: $e');
    }
  }

  void _startStreaming() async {
    if (_isStreaming) return;
    setState(() => _isStreaming = true);
    try {
      final stream = _client.streamLogs(LogRequest());
      await for (final log in stream) {
        print('Client received: ${log.message}');
      }
    } catch (e) {
      print('Error in stream: $e');
    } finally {
      setState(() => _isStreaming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('gRPC Debug Prototype'),
        backgroundColor: Colors.blueAccent.withOpacity(0.1),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.hub, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 24),
                  Text('User: $_userName', style: Theme.of(context).textTheme.headlineMedium),
                  Text('Age: $_userAge', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _getUser,
                        icon: const Icon(Icons.person),
                        label: const Text('Get User (Unary)'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isStreaming ? null : _startStreaming,
                        icon: const Icon(Icons.stream),
                        label: Text(_isStreaming ? 'Streaming...' : 'Start Logs (Stream)'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const GrpcDebugOverlay(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel.shutdown();
    super.dispose();
  }
}
