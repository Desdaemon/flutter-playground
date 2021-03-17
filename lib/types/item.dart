import 'package:json_annotation/json_annotation.dart';

part 'item.g.dart';

@JsonSerializable()
class Item {
  /// The item's unique id.
  final int id;

  /// `true` if the item is deleted.
  final bool? deleted;

  /// The type of item.
  final Items? type;

  /// The username of the item's author.
  final String? by;

  /// Creation date of the item, in [Unix Time](http://en.wikipedia.org/wiki/Unix_time)
  @JsonKey(fromJson: parseTime, toJson: milliseconds)
  final DateTime? time;

  /// The comment, story or poll text. HTML.
  final String? text;

  /// `true` if the item is dead.
  final bool? dead;

  /// The comment's parent: either another comment or the relevant story.
  final int? parent;

  /// The pollopt's associated poll.
  final int? poll;

  /// The ids of the item's comments, in ranked display order.
  final List<int>? kids;

  /// The URL of the story.
  final String? url;

  /// The story's score, or the votes for a pollopt.
  final int? score;

  /// The title of the story, poll or job. HTML.
  final String? title;

  /// A list or related pollopts, in display order.
  final List<int>? parts;

  /// In the case of stories or polls, the total comment count.
  final int? descendants;

  static DateTime? parseTime(int? ms) => ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  static int? milliseconds(DateTime? dt) => dt?.millisecondsSinceEpoch;

  const Item(this.id,
      {this.text,
      this.dead,
      this.parent,
      this.poll,
      this.kids,
      this.url,
      this.score,
      this.title,
      this.parts,
      this.type,
      this.by,
      this.time,
      this.deleted,
      this.descendants});

  static const fromJson = _$ItemFromJson;
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

enum Items { job, story, comment, poll, pollopt }
