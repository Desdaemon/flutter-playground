// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
    json['id'] as String,
    DateTime.parse(json['created'] as String),
    json['karma'] as int,
    about: json['about'] as String?,
    submitted:
        (json['submitted'] as List<dynamic>?)?.map((e) => e as int).toList(),
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'created': instance.created.toIso8601String(),
      'karma': instance.karma,
      'about': instance.about,
      'submitted': instance.submitted,
    };
