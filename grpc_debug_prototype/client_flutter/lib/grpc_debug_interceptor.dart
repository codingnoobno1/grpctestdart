import 'dart:async';
import 'package:grpc/grpc.dart';

/// A simple log entry for gRPC traffic.
class GrpcLogEntry {
  final String method;
  final String type; // 'Request' or 'Response' or 'Stream'
  final String payload;
  final DateTime timestamp;

  GrpcLogEntry({
    required this.method,
    required this.type,
    required this.payload,
    required this.timestamp,
  });

  @override
  String toString() => '[$timestamp] $method ($type): $payload';
}

/// A global stream controller to broadcast logs to the UI.
final StreamController<GrpcLogEntry> grpcLogController = StreamController<GrpcLogEntry>.broadcast();

class DebugInterceptor extends ClientInterceptor {
  @override
  ResponseFuture<R> interceptUnary<Q, R>(
      ClientMethod<Q, R> method, Q request, CallOptions options, invoker) {
    _log(method.path, 'Request', request.toString());

    final response = invoker(method, request, options);

    response.then((value) {
      _log(method.path, 'Response', value.toString());
    }).catchError((error) {
      _log(method.path, 'Error', error.toString());
    });

    return response;
  }

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
      ClientMethod<Q, R> method, Stream<Q> requests, CallOptions options, invoker) {
    _log(method.path, 'Stream Start', '');

    final responseStream = invoker(method, requests, options);

    // We wrap the response stream to intercept each message.
    final controller = StreamController<R>();
    responseStream.listen(
      (value) {
        _log(method.path, 'Stream Message', value.toString());
        controller.add(value);
      },
      onError: (error) {
        _log(method.path, 'Stream Error', error.toString());
        controller.addError(error);
      },
      onDone: () {
        _log(method.path, 'Stream Done', '');
        controller.close();
      },
    );

    return ResponseStream(controller.stream);
  }

  void _log(String method, String type, String payload) {
    final entry = GrpcLogEntry(
      method: method,
      type: type,
      payload: payload,
      timestamp: DateTime.now(),
    );
    print(entry);
    grpcLogController.add(entry);
  }
}
