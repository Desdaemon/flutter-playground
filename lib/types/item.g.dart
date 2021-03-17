// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) {
  return Item(
    json['id'] as int,
    text: json['text'] as String?,
    dead: json['dead'] as bool?,
    parent: json['parent'] as int?,
    poll: json['poll'] as int?,
    kids: (json['kids'] as List<dynamic>?)?.map((e) => e as int).toList(),
    url: json['url'] as String?,
    score: json['score'] as int?,
    title: json['title'] as String?,
    parts: (json['parts'] as List<dynamic>?)?.map((e) => e as int).toList(),
    type: _$enumDecodeNullable(_$ItemsEnumMap, json['type']),
    by: json['by'] as String?,
    time: Item.parseTime(json['time'] as int?),
    deleted: json['deleted'] as bool?,
    descendants: json['descendants'] as int?,
  );
}

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'id': instance.id,
      'deleted': instance.deleted,
      'type': _$ItemsEnumMap[instance.type],
      'by': instance.by,
      'time': Item.milliseconds(instance.time),
      'text': instance.text,
      'dead': instance.dead,
      'parent': instance.parent,
      'poll': instance.poll,
      'kids': instance.kids,
      'url': instance.url,
      'score': instance.score,
      'title': instance.title,
      'parts': instance.parts,
      'descendants': instance.descendants,
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

K? _$enumDecodeNullable<K, V>(
  Map<K, V> enumValues,
  dynamic source, {
  K? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<K, V>(enumValues, source, unknownValue: unknownValue);
}

const _$ItemsEnumMap = {
  Items.job: 'job',
  Items.story: 'story',
  Items.comment: 'comment',
  Items.poll: 'poll',
  Items.pollopt: 'pollopt',
};
