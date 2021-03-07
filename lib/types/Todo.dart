import 'package:json_annotation/json_annotation.dart';

part 'Todo.g.dart';

@JsonSerializable()
class Todo {
  static const fromJson = _$TodoFromJson;
  static const toJson = _$TodoToJson;

  static int _id = 0;
  int id;
  String? content;
  Todo({this.content}): id = _id++;
}