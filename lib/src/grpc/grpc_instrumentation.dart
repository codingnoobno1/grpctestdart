// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:developer';
import 'package:grpc/grpc.dart';

/// A gRPC ClientInterceptor that instruments request and response sizes.
class SocketTraceGrpcInterceptor implements ClientInterceptor {
  @override
  ResponseStream<R> interceptStreaming<Q, R>(
    ClientMethod<Q, R> method,
    Stream<Q> requests,
    CallOptions options,
    ClientStreamingInvoker<Q, R> invoker,
  ) {
    final instrumentedRequests = requests.map((request) {
      _recordEvent(request, 'send', method.path);
      return request;
    });

    final response = invoker(method, instrumentedRequests, options);

    // Cast the transformed stream back to ResponseStream
    final transformedStream = response.map((data) {
      _recordEvent(data, 'receive', method.path);
      return data;
    });

    return transformedStream as ResponseStream<R>;
  }

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientUnaryInvoker<Q, R> invoker,
  ) {
    _recordEvent(request, 'send', method.path);

    final response = invoker(method, request, options);

    // Transform the response future to record events
    response.then((data) {
      _recordEvent(data, 'receive', method.path);
      return data;
    });

    return response;
  }

  void _recordEvent(dynamic data, String direction, String path) {
    // Note: This is an approximation of the serialized size.
    // In a real gRPC call, the size would be the length of the protobuf-encoded bytes.
    int size = 0;
    if (data is List<int>) {
      size = data.length;
    } else if (data is String) {
      size = data.length;
    } else {
      // If we can't easily get the size, we might need to serialize it or use a proxy.
      // For now, we'll mark it as unknown or try to estimate.
      try {
        // Many gRPC generated classes have a `writeToBuffer()` method.
        if (data.runtimeType.toString().contains('GeneratedMessage')) {
          size = (data as dynamic).writeToBuffer().length;
        }
      } catch (_) {}
    }

    Timeline.instantSync(
      'WebSocketFrame', // Reusing the same name for VMTraceClient compatibility
      arguments: {
        'direction': direction,
        'size': size,
        'type': 'grpc',
        'path': path,
      },
    );
  }
}
