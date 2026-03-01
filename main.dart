import 'dart:async';
import 'package:grpc/grpc.dart';
// Relative import to the generated proto files
import 'package:grpc_debug_server/generated/debug.pbgrpc.dart';

class DebugServiceImpl extends DebugServiceBase {
  @override
  Future<UserResponse> getUser(ServiceCall call, UserRequest request) async {
    print('Received GetUser request for ID: ${request.id}');
    return UserResponse()
      ..name = "Tushar"
      ..age = 22;
  }

  @override
  Stream<LogMessage> streamLogs(ServiceCall call, LogRequest request) async* {
    print('Received StreamLogs request');
    for (int i = 0; i < 5; i++) {
      final log = LogMessage()..message = "Log $i at ${DateTime.now()}";
      print('Streaming: ${log.message}');
      yield log;
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

Future<void> main() async {
  print("Starting main at d:\\dart\\grpc\\main.dart...");
  print("Starting gRPC Debug Server...");

  try {
    final server = Server.create(
      services: [DebugServiceImpl()],
      codecRegistry:
          CodecRegistry(codecs: const [GzipCodec(), IdentityCodec()]),
    );

    print("Server instance created, attempting to serve on port 50051...");

    await server.serve(port: 50051);

    print('Server listening on port ${server.port}...');
    print('Press Ctrl+C to stop the server.');
    
    // Keep the process alive
    await Future.delayed(const Duration(days: 365));
  } catch (e, stack) {
    print("CRITICAL: Server failed to start: $e");
    print("Stack Trace:\n$stack");
  }
}
