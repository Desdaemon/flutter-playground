import 'package:yata_flutter/api/hacker_news.dart';
import 'package:yata_flutter/types/item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('get story', () async {
    final story = await item(8863);
    expect(story?.by, "dhouston");
    expect(story?.type, Items.story);
    expect(story?.url, 'http://www.getdropbox.com/u/2/screencast.html');
  });

  test('get invalid story', () async {
    final story = await item(-1);
    expect(story, null);
  });
}
