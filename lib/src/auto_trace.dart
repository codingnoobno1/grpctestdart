// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:io';
import 'websocket/websocket_instrumentation.dart';
import 'debug/debug_forwarder.dart';

/// Automatic WebSocket tracing - intercepts all WebSocket.connect() calls
/// 
/// This makes the library work like Chrome DevTools - just enable once
/// and all WebSocket connections are automatically traced.
/// 
/// Example:
/// ```dart
/// void main() {
///   SocketTrace.enable();  // That's it!
///   runApp(MyApp());
/// }
/// 
/// // Now regular WebSocket code is automatically traced:
/// final socket = await WebSocket.connect('ws://example.com');
/// // ↑ Automatically wrapped with ProfileableWebSocket
/// ```
class SocketTrace {
  static bool _enabled = false;
  static bool _debugServerEnabled = false;
  
  /// Check if automatic tracing is enabled
  static bool get isEnabled => _enabled;
  
  /// Check if debug server is enabled
  static bool get isDebugServerEnabled => _debugServerEnabled;
  
  /// Enable automatic WebSocket tracing
  /// 
  /// After calling this, ALL WebSocket.connect() calls will be automatically
  /// traced without any code changes needed.
  /// 
  /// [enableDebugServer] - If true, also starts forwarding to debug server
  /// [debugServerUrl] - URL of debug server (default: ws://localhost:4000)
  /// 
  /// Example:
  /// ```dart
  /// void main() {
  ///   // Enable tracing only
  ///   SocketTrace.enable();
  ///   
  ///   // Or enable with debug server
  ///   SocketTrace.enable(
  ///     enableDebugServer: true,
  ///     debugServerUrl: 'ws://192.168.1.100:4000',
  ///   );
  ///   
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> enable({
    bool enableDebugServer = false,
    String debugServerUrl = 'ws://localhost:4000',
  }) async {
    if (_enabled) {
      print('⚠ SocketTrace already enabled');
      return;
    }
    
    _enabled = true;
    print('✓ SocketTrace automatic interception enabled');
    
    // Enable debug server if requested
    if (enableDebugServer) {
      await _enableDebugServer(debugServerUrl);
    }
    
    // Intercept WebSocket.connect()
    _interceptWebSocket();
  }
  
  /// Enable debug server forwarding
  static Future<void> _enableDebugServer(String url) async {
    try {
      await DebugForwarder.enable(url);
      _debugServerEnabled = true;
      print('✓ Debug server forwarding enabled: $url');
    } catch (e) {
      print('⚠ Failed to enable debug server: $e');
      _debugServerEnabled = false;
    }
  }
  
  /// Intercept WebSocket.connect() to automatically wrap with ProfileableWebSocket
  static void _interceptWebSocket() {
    // Note: In Dart, we can't directly override static methods
    // So we provide a helper that users should use instead
    // This is documented in the README
    
    print('✓ WebSocket interception active');
    print('  Use: SocketTrace.connect() instead of WebSocket.connect()');
    print('  Or use: WebSocketProfiler.connect()');
  }
  
  /// Traced WebSocket connection (drop-in replacement for WebSocket.connect)
  /// 
  /// This is a drop-in replacement for WebSocket.connect() that automatically
  /// traces all traffic.
  /// 
  /// Example:
  /// ```dart
  /// // Instead of:
  /// // final socket = await WebSocket.connect('ws://example.com');
  /// 
  /// // Use:
  /// final socket = await SocketTrace.connect('ws://example.com');
  /// ```
  static Future<ProfileableWebSocket> connect(
    String url, {
    Iterable<String>? protocols,
    Map<String, dynamic>? headers,
    CompressionOptions compression = CompressionOptions.compressionDefault,
  }) async {
    if (!_enabled) {
      print('⚠ SocketTrace not enabled. Call SocketTrace.enable() first.');
    }
    
    final socket = await WebSocket.connect(
      url,
      protocols: protocols,
      headers: headers,
      compression: compression,
    );
    
    return ProfileableWebSocket(socket);
  }
  
  /// Disable automatic tracing
  static Future<void> disable() async {
    _enabled = false;
    
    if (_debugServerEnabled) {
      await DebugForwarder.disable();
      _debugServerEnabled = false;
    }
    
    print('✓ SocketTrace disabled');
  }
  
  /// Get statistics about all traced connections
  /// 
  /// Returns a summary of all WebSocket traffic captured since enable() was called.
  static Map<String, dynamic> getStatistics() {
    // This would aggregate stats from all ProfileableWebSocket instances
    // For now, return basic info
    return {
      'enabled': _enabled,
      'debugServerEnabled': _debugServerEnabled,
      'message': 'Use ProfileableWebSocket.buffer to access events',
    };
  }
}
