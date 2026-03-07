// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'websocket_event.dart';

/// A wrapper around [WebSocket] that instruments frame events.
class ProfileableWebSocket implements WebSocket {
  ProfileableWebSocket(this._socket);

  final WebSocket _socket;
  final List<SocketEvent> buffer = [];

  @override
  void add(dynamic data) {
    _recordEvent(data, 'send');
    _socket.add(data);
  }

  @override
  void addUtf8Text(List<int> bytes) {
    _recordEvent(bytes, 'send', isUtf8: true);
    _socket.addUtf8Text(bytes);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _socket.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream stream) => _socket.addStream(stream);

  @override
  Future<void> close([int? code, String? reason]) =>
      _socket.close(code, reason);

  @override
  int? get closeCode => _socket.closeCode;

  @override
  String? get closeReason => _socket.closeReason;

  @override
  String get extensions => _socket.extensions;

  @override
  StreamSubscription listen(
    void Function(dynamic)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _socket.listen(
      (data) {
        _recordEvent(data, 'receive');
        onData?.call(data);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  String? get protocol => _socket.protocol;

  @override
  int get readyState => _socket.readyState;

  @override
  Duration? get pingInterval => _socket.pingInterval;

  @override
  set pingInterval(Duration? value) => _socket.pingInterval = value;

  @override
  Future get done => _socket.done;

  @override
  Future<bool> any(bool Function(dynamic element) test) => _socket.any(test);

  @override
  Stream<dynamic> asBroadcastStream({
    void Function(StreamSubscription<dynamic> subscription)? onListen,
    void Function(StreamSubscription<dynamic> subscription)? onCancel,
  }) => _socket.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(dynamic event) convert) =>
      _socket.asyncExpand(convert);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(dynamic event) convert) =>
      _socket.asyncMap(convert);

  @override
  Stream<R> cast<R>() => _socket.cast<R>();

  @override
  Future<bool> contains(Object? needle) => _socket.contains(needle);

  @override
  Stream<dynamic> distinct([
    bool Function(dynamic previous, dynamic next)? equals,
  ]) => _socket.distinct(equals);

  @override
  Future<E> drain<E>([E? futureValue]) => _socket.drain<E>(futureValue);

  @override
  Future<dynamic> elementAt(int index) => _socket.elementAt(index);

  @override
  Future<bool> every(bool Function(dynamic element) test) =>
      _socket.every(test);

  @override
  Stream<S> expand<S>(Iterable<S> Function(dynamic element) convert) =>
      _socket.expand(convert);

  @override
  Future<dynamic> get first => _socket.first;

  @override
  Future<dynamic> firstWhere(
    bool Function(dynamic element) test, {
    dynamic Function()? orElse,
  }) => _socket.firstWhere(test, orElse: orElse);

  @override
  Future<S> fold<S>(
    S initialValue,
    S Function(S previous, dynamic element) combine,
  ) => _socket.fold(initialValue, combine);

  @override
  Future<dynamic> forEach(void Function(dynamic element) action) =>
      _socket.forEach(action);

  @override
  Stream<dynamic> handleError(
    Function onError, {
    bool Function(dynamic error)? test,
  }) => _socket.handleError(onError, test: test);

  @override
  bool get isBroadcast => _socket.isBroadcast;

  @override
  Future<bool> get isEmpty => _socket.isEmpty;

  @override
  Future<String> join([String separator = '']) => _socket.join(separator);

  @override
  Future<dynamic> get last => _socket.last;

  @override
  Future<dynamic> lastWhere(
    bool Function(dynamic element) test, {
    dynamic Function()? orElse,
  }) => _socket.lastWhere(test, orElse: orElse);

  @override
  Future<int> get length => _socket.length;

  @override
  Stream<S> map<S>(S Function(dynamic event) convert) => _socket.map(convert);

  @override
  Future pipe(StreamConsumer<dynamic> streamConsumer) =>
      _socket.pipe(streamConsumer);

  @override
  Future<dynamic> reduce(
    dynamic Function(dynamic combined, dynamic element) combine,
  ) => _socket.reduce(combine);

  @override
  Future<dynamic> get single => _socket.single;

  @override
  Future<dynamic> singleWhere(
    bool Function(dynamic element) test, {
    dynamic Function()? orElse,
  }) => _socket.singleWhere(test, orElse: orElse);

  @override
  Stream<dynamic> skip(int count) => _socket.skip(count);

  @override
  Stream<dynamic> skipWhile(bool Function(dynamic element) test) =>
      _socket.skipWhile(test);

  @override
  Stream<dynamic> take(int count) => _socket.take(count);

  @override
  Stream<dynamic> takeWhile(bool Function(dynamic element) test) =>
      _socket.takeWhile(test);

  @override
  Stream<dynamic> timeout(
    Duration timeLimit, {
    void Function(EventSink<dynamic> sink)? onTimeout,
  }) => _socket.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<dynamic>> toList() => _socket.toList();

  @override
  Future<Set<dynamic>> toSet() => _socket.toSet();

  @override
  Stream<S> transform<S>(StreamTransformer<dynamic, S> streamTransformer) =>
      _socket.transform(streamTransformer);

  @override
  Stream<dynamic> where(bool Function(dynamic event) test) =>
      _socket.where(test);

  void _recordEvent(dynamic data, String direction, {bool isUtf8 = false}) {
    final size = _getSize(data);
    final type = (data is String || isUtf8) ? 'text' : 'binary';
    final event = SocketEvent(
      time: DateTime.now(),
      size: size,
      type: type,
      direction: direction,
    );
    buffer.add(event);

    Timeline.instantSync(
      'WebSocketFrame',
      arguments: {'direction': direction, 'size': size, 'type': type},
    );
  }

  int _getSize(dynamic data) {
    if (data is String) return data.length;
    if (data is List<int>) return data.length;
    return 0;
  }
}
