import 'dart:convert';

import 'package:yata_flutter/types/item.dart';
import 'package:yata_flutter/types/user.dart';
import 'package:http/http.dart';

final base = Uri.parse('https://hacker-news.firebaseio.com');

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
V? map<U, V>(U? source, V Function(U) transformer) => source != null ? transformer(source) : null;

Future<Item?> item(int id) =>
    fetch<Map<String, dynamic>>('/v0/item/$id.json').then((value) => map(value, Item.fromJson));

Future<User?> user(String id) =>
    fetch<Map<String, dynamic>>('/v0/user/$id.json').then((value) => map(value, User.fromJson));

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
Future<T?> fetch<T>(String path) async {
  final res = await get(base.resolve(path));
  try {
    return jsonDecode(res.body) as T;
  } catch (_) {
    return null;
  }
}
