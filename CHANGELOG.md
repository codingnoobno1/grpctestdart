## 1.0.0

Initial release of socket_trace!

### Features

- ✅ Automatic WebSocket tracing with `SocketTrace.enable()`
- ✅ Drop-in replacement for `WebSocket.connect()` with `SocketTrace.connect()`
- ✅ Embedded debug server that runs in background isolate
- ✅ Modern web UI for live packet monitoring at http://localhost:4000
- ✅ Timeline integration via VM service for DevTools
- ✅ gRPC interceptor for tracing gRPC traffic
- ✅ Real-time statistics (packet counts, bytes transferred)
- ✅ Flutter UI widget for in-app debugging
- ✅ Event buffering and replay
- ✅ Pause/resume packet capture
- ✅ Export captured packets to JSON
- ✅ Zero configuration - works out of the box

### API

- `SocketTrace.enable()` - Enable automatic tracing
- `SocketTrace.connect()` - Traced WebSocket connection
- `SocketTrace.disable()` - Disable tracing
- `EmbeddedDebugServer.start()` - Start background debug server
- `EmbeddedDebugServer.stop()` - Stop debug server
- `WebSocketProfiler.connect()` - Manual profiling
- `SocketTraceGrpcInterceptor` - gRPC interceptor
- `SocketTraceView` - Flutter UI widget

### Documentation

- Complete API documentation
- Usage examples
- Integration guides
- Troubleshooting tips

### Examples

- Basic usage example
- Automatic tracing demo
- gRPC integration example
- Flutter UI integration

### Supported Platforms

- Flutter (iOS, Android, Web, Desktop)
- Dart CLI applications

### Requirements

- Dart SDK: >=3.0.0 <4.0.0
- Flutter: >=3.0.0
