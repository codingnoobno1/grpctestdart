import 'dart:async';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:grpc_debug_server/generated/debug.pbgrpc.dart';

class DebugServiceImpl extends DebugServiceBase {
  @override
  Future<UserResponse> getUser(
      ServiceCall call, UserRequest request) async {
    print('[Unary] GetUser called with id: ${request.id}');

    return UserResponse()
      ..name = "Tushar"
      ..age = 22;
  }

  @override
  Stream<LogMessage> streamLogs(
      ServiceCall call, LogRequest request) async* {
    print('[Stream] StreamLogs started');

    for (int i = 0; i < 5; i++) {
      final message =
          LogMessage()..message = "Log $i at ${DateTime.now()}";

      print('[Stream] Sending: ${message.message}');
      yield message;

      await Future.delayed(const Duration(seconds: 1));
    }

    print('[Stream] StreamLogs finished');
  }
}

Future<void> main() async {
  print('====================================');
  print('Starting gRPC Debug Server...');
  print('====================================');

  final server = Server(
    [DebugServiceImpl()],
    const <Interceptor>[],
  );

  try {
    await server.serve(
      port: 50051,
      address: InternetAddress.anyIPv4,
    );

    print('Server listening on port ${server.port}');
    print('Press CTRL+C to stop.');

    // Graceful shutdown on CTRL+C
    ProcessSignal.sigint.watch().listen((signal) async {
      print('\nShutting down server...');
      await server.shutdown();
      exit(0);
    });

  } catch (e, stackTrace) {
    print('CRITICAL: Failed to start server');
    print('Error: $e');
    print('StackTrace:\n$stackTrace');
  }
}