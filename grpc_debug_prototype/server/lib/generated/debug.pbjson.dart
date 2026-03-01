// This is a generated file - do not edit.
//
// Generated from debug.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use userRequestDescriptor instead')
const UserRequest$json = {
  '1': 'UserRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `UserRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userRequestDescriptor =
    $convert.base64Decode('CgtVc2VyUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use userResponseDescriptor instead')
const UserResponse$json = {
  '1': 'UserResponse',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'age', '3': 2, '4': 1, '5': 5, '10': 'age'},
  ],
};

/// Descriptor for `UserResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userResponseDescriptor = $convert.base64Decode(
    'CgxVc2VyUmVzcG9uc2USEgoEbmFtZRgBIAEoCVIEbmFtZRIQCgNhZ2UYAiABKAVSA2FnZQ==');

@$core.Deprecated('Use logRequestDescriptor instead')
const LogRequest$json = {
  '1': 'LogRequest',
};

/// Descriptor for `LogRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logRequestDescriptor =
    $convert.base64Decode('CgpMb2dSZXF1ZXN0');

@$core.Deprecated('Use logMessageDescriptor instead')
const LogMessage$json = {
  '1': 'LogMessage',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `LogMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logMessageDescriptor = $convert
    .base64Decode('CgpMb2dNZXNzYWdlEhgKB21lc3NhZ2UYASABKAlSB21lc3NhZ2U=');
