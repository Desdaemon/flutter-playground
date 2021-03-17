import 'package:flutter/material.dart';
import 'package:yata_flutter/api/hacker_news.dart';
import 'package:yata_flutter/types/item.dart';

class FrontPageItem extends StatefulWidget {
  /// The id of the item.
  final int id;
  const FrontPageItem(this.id, {Key? key}) : super(key: key);
  @override
  _FrontPageItemState createState() => _FrontPageItemState();
}

class _FrontPageItemState extends State<FrontPageItem> {
  late final Future<Item?> fut;

  @override
  void initState() {
    super.initState();
    fut = item(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Item?>(
      future: fut,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const CircularProgressIndicator();
        final d = snapshot.data;
        if (d != null) {
          return Card(
            child: Column(
              children: [
                Text(d.by ?? 'Unknown'),
                if (d.text != null) Text(d.text!),
              ],
            ),
          );
        }
        return Card(
          child: Text('No data for item ${widget.id}'),
        );
      },
    );
  }
}
