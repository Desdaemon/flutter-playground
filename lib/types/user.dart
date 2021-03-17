import 'package:json_annotation/json_annotation.dart';

part "user.g.dart";

@JsonSerializable()
class User {
  final String id;
  final DateTime created;
  final int karma;
  final String? about;
  final List<int>? submitted;
  User(this.id, this.created, this.karma, {this.about, this.submitted});

  static const fromJson = _$UserFromJson;
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
