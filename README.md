# socket_trace 🔍

WebSocket and gRPC tracing library with automatic packet capture, timeline integration, and live debugging UI. Like Chrome DevTools for Flutter!

[![pub package](https://img.shields.io/pub/v/socket_trace.svg)](https://pub.dev/packages/socket_trace)
[![license](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](https://github.com/yourusername/socket_trace/blob/main/LICENSE)

## 🌟 Key Facilities

`socket_trace` provides four main ways to debug your network traffic:

1.  **Automatic Interception**: One-line setup to capture all traffic.
2.  **Live Web Dashboard**: A modern, real-time UI running in your browser.
3.  **In-App Debugger**: A Flutter widget to inspect traffic inside your app.
4.  **CLI Tool**: A standalone server to collect traces from multiple devices.

---

## 🚀 Quick Start

### 1. Register the Package
Add `socket_trace` to your `pubspec.yaml`:

```yaml
dependencies:
  socket_trace: ^1.0.0
```

### 2. Enable & Start Server
Initialize the tracer in your `main()` function:

```dart
import 'package:socket_trace/socket_trace.dart';

void main() async {
  // 1. Enable interception and optionally forward to a server
  await SocketTrace.enable(enableDebugServer: true);
  
  // 2. Start the embedded dashboard (accessible at http://localhost:4000)
  await EmbeddedDebugServer.start(port: 4000);
  
  runApp(const MyApp());
}
```

### 3. Trace Connections
Use `SocketTrace.connect()` as a drop-in replacement for `WebSocket.connect()`:

```dart
// After (Automatically traced and visible in dashboard!):
final socket = await SocketTrace.connect('wss://echo.websocket.org');
socket.add('Hello DevTools!');
```

---

## 🛠️ Facility Deep Dive

### 1. Web UI Debugger (Live Monitor)
When you start `EmbeddedDebugServer`, a premium dashboard is hosted locally using a background `Isolate`.

- **Access**: Open `http://localhost:4000` in any browser.
- **Features**: 
  - **Real-time Streaming**: Packets appear instantly as they are sent/received.
  - **Search & Filter**: Find specific payloads or filter by gRPC/WebSocket.
  - **Pause/Resume**: Stop the firehose of data to inspect a specific sequence.
  - **Dark Mode**: Premium glassmorphism design optimized for long sessions.

### 2. In-App Flutter UI
For on-device inspection, use `SocketTraceView`. This is perfect for QA teams who don't have access to a terminal.

```dart
import 'package:socket_trace/socket_trace.dart';

class NetworkInspector extends StatefulWidget {
  @override
  _NetworkInspectorState createState() => _NetworkInspectorState();
}

class _NetworkInspectorState extends State<NetworkInspector> {
  final List<SocketEvent> _events = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Logs')),
      body: SocketTraceView(
        events: _events,
        onClear: () => setState(() => _events.clear()),
      ),
    );
  }
}
```

### 3. CLI Facility (Team Debugging)
The standalone CLI tool allows you to run a central server that multiple developers or devices can stream to.

**Run the CLI server:**
```bash
# Install globally
dart pub global activate socket_trace
socket_trace 4000

# Or run via project
dart run socket_trace 4000
```

**Connect your app to the CLI server (Physical Device):**
```dart
await SocketTrace.enable(
  enableDebugServer: true,
  debugServerUrl: 'ws://192.168.1.5:4000', // Use your machine's local IP
);
```

### 4. gRPC Facility
Trace gRPC calls with ease using the provided interceptor. It automatically calculates packet sizes and captures method paths.

```dart
import 'package:socket_trace/socket_trace.dart';

final channel = ClientChannel('localhost', port: 50051);
final client = GreeterClient(
  channel,
  interceptors: [SocketTraceGrpcInterceptor()],
);
```

---

## 🧠 How it Works

1.  **Interception**: `SocketTrace.connect` creates a `ProfileableWebSocket` wrapper around the standard `WebSocket`.
2.  **Telemetry**: Every `add()` (send) and `listen()` (receive) call is timestamped and recorded into a local buffer.
3.  **Forwarding**: If `enableDebugServer` is true, events are serialized to JSON and sent via a background WebSocket to the `EmbeddedDebugServer`.
4.  **Isolate Safety**: The server runs in a separate `Isolate` to ensure that network debugging never impacts your app's main thread and UI performance.

---

## 💡 Advanced Usage

### Physical Device Connection
To view logs from a physical phone on your computer's browser:
1. Ensure both are on the same Wi-Fi.
2. Find your computer's local IP.
3. Start the server on `0.0.0.0` (default behavior).
4. Point the app to your IP: `SocketTrace.enable(debugServerUrl: 'ws://<YOUR_IP>:4000')`.

### Timeline Integration (VM Service)
All events are automatically sent to the **Dart DevTools Timeline**. Open Flutter DevTools, go to the "Performance" tab, and you'll see `WebSocketFrame` events synchronized with your app's frames.

---

## ❓ Troubleshooting & FAQ

**Q: My dashboard doesn't show any packets?**
*   Check if `SocketTrace.enable(enableDebugServer: true)` was called before any connections.
*   Ensure you are using `SocketTrace.connect()` instead of `WebSocket.connect()`.

**Q: "Address already in use" error?**
*   Another process (perhaps a previous run) is using port 4000. Use `EmbeddedDebugServer.start(port: 4001)` to change it.

**Q: Does this work in Production?**
*   While efficient, we recommend wrapping the enablement in a debug-only check:
    ```dart
    if (kDebugMode) {
      await SocketTrace.enable(enableDebugServer: true);
    }
    ```

---

## 📖 API Documentation

### `SocketTrace`
- `static Future<void> enable({bool enableDebugServer, String debugServerUrl})`: Initializes the system.
- `static Future<ProfileableWebSocket> connect(...)`: Drop-in replacement for `WebSocket.connect`.
- `static void disable()`: Stops all interception and closes debug connections.

### `EmbeddedDebugServer`
- `static Future<bool> start({int port})`: Starts the background Web Dashboard.
- `static void stop()`: Kills the server isolate.

---

## 📝 License
BSD-3-Clause License. See [LICENSE](LICENSE) for details.
