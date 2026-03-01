// This is a generated file - do not edit.
//
// Generated from debug.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'debug.pb.dart' as $0;

export 'debug.pb.dart';

@$pb.GrpcServiceName('debug.DebugService')
class DebugServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  DebugServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.UserResponse> getUser(
    $0.UserRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getUser, request, options: options);
  }

  $grpc.ResponseStream<$0.LogMessage> streamLogs(
    $0.LogRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamLogs, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getUser = $grpc.ClientMethod<$0.UserRequest, $0.UserResponse>(
      '/debug.DebugService/GetUser',
      ($0.UserRequest value) => value.writeToBuffer(),
      $0.UserResponse.fromBuffer);
  static final _$streamLogs = $grpc.ClientMethod<$0.LogRequest, $0.LogMessage>(
      '/debug.DebugService/StreamLogs',
      ($0.LogRequest value) => value.writeToBuffer(),
      $0.LogMessage.fromBuffer);
}

@$pb.GrpcServiceName('debug.DebugService')
abstract class DebugServiceBase extends $grpc.Service {
  $core.String get $name => 'debug.DebugService';

  DebugServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.UserRequest, $0.UserResponse>(
        'GetUser',
        getUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UserRequest.fromBuffer(value),
        ($0.UserResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LogRequest, $0.LogMessage>(
        'StreamLogs',
        streamLogs_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.LogRequest.fromBuffer(value),
        ($0.LogMessage value) => value.writeToBuffer()));
  }

  $async.Future<$0.UserResponse> getUser_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.UserRequest> $request) async {
    return getUser($call, await $request);
  }

  $async.Future<$0.UserResponse> getUser(
      $grpc.ServiceCall call, $0.UserRequest request);

  $async.Stream<$0.LogMessage> streamLogs_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LogRequest> $request) async* {
    yield* streamLogs($call, await $request);
  }

  $async.Stream<$0.LogMessage> streamLogs(
      $grpc.ServiceCall call, $0.LogRequest request);
}
