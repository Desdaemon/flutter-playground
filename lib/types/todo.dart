import 'package:json_annotation/json_annotation.dart';

part 'todo.g.dart';

@JsonSerializable()
class Todo {
  static int _id = 0;
  static const currentFieldId = 2;

  final int id;
  bool done;
  String? content;

  Todo({int? id, this.content, this.done = false}) : id = id != null ? (_id = _id < id ? id : _id + 1) : _id++;

  Map<String, dynamic> toJson() => _$TodoToJson(this);
  static const fromJson = _$TodoFromJson;

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;
  @override
  int get hashCode => id.hashCode + done.hashCode + content.hashCode;

  @override
  String toString() => 'Todo(id: $id, done: $done, content: $content)';
}
