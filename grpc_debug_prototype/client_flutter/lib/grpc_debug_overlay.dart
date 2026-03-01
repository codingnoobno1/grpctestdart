import 'package:flutter/material.dart';
import 'grpc_debug_interceptor.dart';

class GrpcDebugOverlay extends StatefulWidget {
  const GrpcDebugOverlay({super.key});

  @override
  State<GrpcDebugOverlay> createState() => _GrpcDebugOverlayState();
}

class _GrpcDebugOverlayState extends State<GrpcDebugOverlay> {
  final List<GrpcLogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    grpcLogController.stream.listen((entry) {
      if (mounted) {
        setState(() {
          _logs.insert(0, entry);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: const Border(top: BorderSide(color: Colors.blueAccent, width: 2)),
      ),
      height: 300,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blueAccent.withOpacity(0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'gRPC Debug Inspector',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.white),
                  onPressed: () => setState(() => _logs.clear()),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _logs.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white24),
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${log.timestamp.hour}:${log.timestamp.minute}:${log.timestamp.second}',
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          log.type,
                          style: TextStyle(
                            color: _getTypeColor(log.type),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            log.method,
                            style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (log.payload.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 16),
                        child: Text(
                          log.payload,
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Request': return Colors.greenAccent;
      case 'Response': return Colors.orangeAccent;
      case 'Stream Message': return Colors.cyanAccent;
      case 'Error': return Colors.redAccent;
      default: return Colors.white;
    }
  }
}
