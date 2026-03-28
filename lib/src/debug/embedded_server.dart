// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:io';
import 'dart:isolate';

/// Embedded debug server that runs in the background
/// 
/// This allows the debug server to run as part of your app without
/// needing a separate terminal/process.
/// 
/// Example:
/// ```dart
/// void main() async {
///   await EmbeddedDebugServer.start();
///   runApp(MyApp());
/// }
/// ```
class EmbeddedDebugServer {
  static Isolate? _serverIsolate;
  static bool _isRunning = false;
  
  /// Check if server is running
  static bool get isRunning => _isRunning;
  
  /// Start the embedded debug server
  /// 
  /// [port] - Port to listen on (default: 4000)
  /// [autoStart] - If true, starts automatically (default: true)
  /// 
  /// Returns true if started successfully
  static Future<bool> start({int port = 4000, bool autoStart = true}) async {
    if (_isRunning) {
      print('⚠ Debug server already running');
      return true;
    }
    
    if (!autoStart) {
      print('ℹ Debug server auto-start disabled');
      return false;
    }
    
    try {
      _serverIsolate = await Isolate.spawn(
        _runServer,
        port,
        debugName: 'SocketTraceDebugServer',
      );
      
      _isRunning = true;
      print('✓ Embedded debug server started on port $port');
      print('  Open http://localhost:$port in your browser');
      return true;
    } catch (e) {
      print('⚠ Failed to start embedded debug server: $e');
      _isRunning = false;
      return false;
    }
  }
  
  /// Stop the embedded debug server
  static void stop() {
    if (_serverIsolate != null) {
      _serverIsolate!.kill(priority: Isolate.immediate);
      _serverIsolate = null;
      _isRunning = false;
      print('✓ Embedded debug server stopped');
    }
  }
  
  /// Server entry point (runs in isolate)
  static Future<void> _runServer(int port) async {
    final clients = <WebSocket>[];
    
    try {
      final server = await HttpServer.bind('0.0.0.0', port);
      print('🔍 Debug server listening on http://0.0.0.0:$port');
      
      await for (HttpRequest req in server) {
        if (WebSocketTransformer.isUpgradeRequest(req)) {
          final ws = await WebSocketTransformer.upgrade(req);
          clients.add(ws);
          
          ws.listen(
            (data) {
              // Broadcast to all other clients
              for (var c in clients) {
                if (c != ws) {
                  try {
                    c.add(data);
                  } catch (e) {
                    clients.remove(c);
                  }
                }
              }
            },
            onDone: () => clients.remove(ws),
            onError: (_) => clients.remove(ws),
          );
        } else {
          // Serve HTML dashboard
          req.response.headers.contentType = ContentType.html;
          req.response.write(_getHtmlDashboard());
          await req.response.close();
        }
      }
    } catch (e) {
      print('❌ Debug server error: $e');
    }
  }
  
  /// Get HTML dashboard
  static String _getHtmlDashboard() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Socket Trace - Live Monitor</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: system-ui, -apple-system, sans-serif;
      background: linear-gradient(135deg, #0a0f1e 0%, #1a1f3e 100%);
      color: #e0e0e0;
      padding: 20px;
    }
    .container { max-width: 1400px; margin: 0 auto; }
    h1 {
      font-size: 24px;
      background: linear-gradient(135deg, #00e5ff 0%, #d500f9 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      margin-bottom: 20px;
    }
    .stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 15px;
      margin-bottom: 20px;
    }
    .stat {
      background: rgba(255, 255, 255, 0.05);
      padding: 15px;
      border-radius: 8px;
      border: 1px solid rgba(255, 255, 255, 0.1);
    }
    .stat-label { font-size: 11px; color: #888; text-transform: uppercase; }
    .stat-value { font-size: 24px; font-weight: bold; color: #00e5ff; }
    .controls {
      background: rgba(255, 255, 255, 0.05);
      padding: 15px;
      border-radius: 8px;
      margin-bottom: 20px;
      display: flex;
      gap: 10px;
    }
    button {
      background: #00e5ff;
      color: #000;
      border: none;
      padding: 10px 20px;
      border-radius: 6px;
      cursor: pointer;
      font-weight: 600;
    }
    button:hover { opacity: 0.8; }
    button.danger { background: #ff5252; color: #fff; }
    table {
      width: 100%;
      background: rgba(255, 255, 255, 0.05);
      border-radius: 8px;
      overflow: hidden;
    }
    th {
      background: rgba(0, 0, 0, 0.3);
      padding: 12px;
      text-align: left;
      font-size: 11px;
      text-transform: uppercase;
      color: #888;
    }
    td {
      padding: 10px 12px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.05);
      font-size: 13px;
    }
    tr:hover { background: rgba(255, 255, 255, 0.03); }
    .badge {
      display: inline-block;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 11px;
      font-weight: 600;
    }
    .badge.send { background: rgba(33, 150, 243, 0.2); color: #2196f3; }
    .badge.receive { background: rgba(156, 39, 176, 0.2); color: #ce93d8; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🔍 Socket Trace Monitor</h1>
    
    <div class="stats">
      <div class="stat">
        <div class="stat-label">Status</div>
        <div class="stat-value" id="status">Waiting...</div>
      </div>
      <div class="stat">
        <div class="stat-label">Total</div>
        <div class="stat-value" id="total">0</div>
      </div>
      <div class="stat">
        <div class="stat-label">Sent</div>
        <div class="stat-value" id="sent">0</div>
      </div>
      <div class="stat">
        <div class="stat-label">Received</div>
        <div class="stat-value" id="received">0</div>
      </div>
    </div>
    
    <div class="controls">
      <button onclick="clearAll()" class="danger">Clear</button>
      <button onclick="togglePause()"><span id="pauseBtn">Pause</span></button>
    </div>
    
    <table>
      <thead>
        <tr>
          <th>Time</th>
          <th>Direction</th>
          <th>Type</th>
          <th>Size</th>
          <th>Node</th>
        </tr>
      </thead>
      <tbody id="packets"></tbody>
    </table>
  </div>
  
  <script>
    let ws, packets = [], isPaused = false;
    let stats = { total: 0, sent: 0, received: 0 };
    
    function connect() {
      ws = new WebSocket('ws://' + location.host);
      ws.onopen = () => {
        document.getElementById('status').textContent = 'Connected';
        document.getElementById('status').style.color = '#00e5ff';
      };
      ws.onmessage = (e) => {
        if (isPaused) return;
        const p = JSON.parse(e.data);
        packets.unshift(p);
        stats.total++;
        if (p.direction === 'send') stats.sent++;
        else stats.received++;
        updateUI();
      };
      ws.onclose = () => {
        document.getElementById('status').textContent = 'Disconnected';
        document.getElementById('status').style.color = '#ff5252';
        setTimeout(connect, 2000);
      };
    }
    
    function updateUI() {
      document.getElementById('total').textContent = stats.total;
      document.getElementById('sent').textContent = stats.sent;
      document.getElementById('received').textContent = stats.received;
      
      const tbody = document.getElementById('packets');
      tbody.innerHTML = packets.slice(0, 100).map(p => `
        <tr>
          <td>\${new Date(p.time).toLocaleTimeString()}</td>
          <td><span class="badge \${p.direction}">\${p.direction}</span></td>
          <td>\${p.type}</td>
          <td>\${p.size}B</td>
          <td>\${p.node || 'N/A'}</td>
        </tr>
      `).join('');
    }
    
    function clearAll() {
      packets = [];
      stats = { total: 0, sent: 0, received: 0 };
      updateUI();
    }
    
    function togglePause() {
      isPaused = !isPaused;
      document.getElementById('pauseBtn').textContent = isPaused ? 'Resume' : 'Pause';
    }
    
    connect();
  </script>
</body>
</html>
''';
  }
}
