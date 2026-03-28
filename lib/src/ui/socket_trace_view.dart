import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../websocket/websocket_event.dart';

class SocketTraceView extends StatefulWidget {
  final List<SocketEvent> events;
  final VoidCallback? onClear;

  const SocketTraceView({super.key, required this.events, this.onClear});

  @override
  State<SocketTraceView> createState() => _SocketTraceViewState();
}

class _SocketTraceViewState extends State<SocketTraceView> {
  final DateFormat _timeFormat = DateFormat('HH:mm:ss.SSS');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Socket Traffic',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (widget.onClear != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onClear,
                  tooltip: 'Clear Logs',
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: widget.events.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Colors.white10),
            itemBuilder: (context, index) {
              final event = widget.events[index];
              final isSend = event.direction.toLowerCase() == 'send';

              return ListTile(
                dense: true,
                leading: Icon(
                  isSend ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isSend ? Colors.blue : Colors.purple,
                  size: 16,
                ),
                title: Row(
                  children: [
                    Text(
                      _timeFormat.format(event.time),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (event.type == 'grpc'
                                    ? Colors.green
                                    : Colors.orange)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color:
                              (event.type == 'grpc'
                                      ? Colors.green
                                      : Colors.orange)
                                  .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        event.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: event.type == 'grpc'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  '${event.size} B',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
