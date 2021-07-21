///
//  Generated code. Do not modify.
//  source: root.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use elementDescriptor instead')
const Element$json = const {
  '1': 'Element',
  '2': const [
    const {'1': 'tag', '3': 1, '4': 1, '5': 11, '6': '.flutter_playground.Tag', '9': 0, '10': 'tag'},
    const {'1': 'text', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'text'},
  ],
  '8': const [
    const {'1': 'value'},
  ],
};

/// Descriptor for `Element`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List elementDescriptor = $convert.base64Decode('CgdFbGVtZW50EisKA3RhZxgBIAEoCzIXLmZsdXR0ZXJfcGxheWdyb3VuZC5UYWdIAFIDdGFnEhQKBHRleHQYAiABKAlIAFIEdGV4dEIHCgV2YWx1ZQ==');
@$core.Deprecated('Use tagDescriptor instead')
const Tag$json = const {
  '1': 'Tag',
  '2': const [
    const {'1': 'tag', '3': 1, '4': 1, '5': 14, '6': '.flutter_playground.Tag.Tags', '10': 'tag'},
    const {'1': 'children', '3': 2, '4': 3, '5': 11, '6': '.flutter_playground.Element', '10': 'children'},
    const {'1': 'style', '3': 3, '4': 1, '5': 9, '10': 'style'},
    const {'1': 'href', '3': 4, '4': 1, '5': 9, '10': 'href'},
    const {'1': 'checked', '3': 5, '4': 1, '5': 8, '10': 'checked'},
  ],
  '4': const [Tag_Tags$json],
};

@$core.Deprecated('Use tagDescriptor instead')
const Tag_Tags$json = const {
  '1': 'Tags',
  '2': const [
    const {'1': 'Paragraph', '2': 0},
    const {'1': 'H1', '2': 1},
    const {'1': 'H2', '2': 2},
    const {'1': 'H3', '2': 3},
    const {'1': 'H4', '2': 4},
    const {'1': 'H5', '2': 5},
    const {'1': 'H6', '2': 6},
    const {'1': 'Blockquote', '2': 7},
    const {'1': 'Pre', '2': 8},
    const {'1': 'OrderedList', '2': 9},
    const {'1': 'UnorderedList', '2': 10},
    const {'1': 'ListItem', '2': 11},
    const {'1': 'Table', '2': 12},
    const {'1': 'TableHead', '2': 13},
    const {'1': 'TableRow', '2': 14},
    const {'1': 'TableCell', '2': 15},
    const {'1': 'TableHeaderCell', '2': 16},
    const {'1': 'Emphasis', '2': 17},
    const {'1': 'Strong', '2': 18},
    const {'1': 'Strikethrough', '2': 19},
    const {'1': 'Anchor', '2': 20},
    const {'1': 'Image', '2': 21},
    const {'1': 'Code', '2': 22},
    const {'1': 'HardBreak', '2': 23},
    const {'1': 'Ruler', '2': 24},
    const {'1': 'Checkbox', '2': 25},
  ],
};

/// Descriptor for `Tag`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagDescriptor = $convert.base64Decode('CgNUYWcSLgoDdGFnGAEgASgOMhwuZmx1dHRlcl9wbGF5Z3JvdW5kLlRhZy5UYWdzUgN0YWcSNwoIY2hpbGRyZW4YAiADKAsyGy5mbHV0dGVyX3BsYXlncm91bmQuRWxlbWVudFIIY2hpbGRyZW4SFAoFc3R5bGUYAyABKAlSBXN0eWxlEhIKBGhyZWYYBCABKAlSBGhyZWYSGAoHY2hlY2tlZBgFIAEoCFIHY2hlY2tlZCLSAgoEVGFncxINCglQYXJhZ3JhcGgQABIGCgJIMRABEgYKAkgyEAISBgoCSDMQAxIGCgJINBAEEgYKAkg1EAUSBgoCSDYQBhIOCgpCbG9ja3F1b3RlEAcSBwoDUHJlEAgSDwoLT3JkZXJlZExpc3QQCRIRCg1Vbm9yZGVyZWRMaXN0EAoSDAoITGlzdEl0ZW0QCxIJCgVUYWJsZRAMEg0KCVRhYmxlSGVhZBANEgwKCFRhYmxlUm93EA4SDQoJVGFibGVDZWxsEA8SEwoPVGFibGVIZWFkZXJDZWxsEBASDAoIRW1waGFzaXMQERIKCgZTdHJvbmcQEhIRCg1TdHJpa2V0aHJvdWdoEBMSCgoGQW5jaG9yEBQSCQoFSW1hZ2UQFRIICgRDb2RlEBYSDQoJSGFyZEJyZWFrEBcSCQoFUnVsZXIQGBIMCghDaGVja2JveBAZ');
