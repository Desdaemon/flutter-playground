import 'dart:math';

import 'package:flutter/material.dart';
import 'package:yata_flutter/widgets/flexbox.dart';

class FlexTest extends StatefulWidget {
  const FlexTest({Key? key}) : super(key: key);

  @override
  _FlexTestState createState() => _FlexTestState();
}

class _FlexTestState extends State<FlexTest> {
  final List<Flexible> children = [];

  static final rng = Random();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => setState(() {
            final flex = rng.nextInt(3) + 1;
            // const flex = 2;
            children.add(Expanded(
                flex: flex,
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.brightness_7),
                  label: Text(flex.toString()),
                )
                // child: Container(
                //   height: 20,
                //   decoration: BoxDecoration(
                //     border: Border.all(color: Colors.white),
                //     color: Colors.white30,
                //   ),
                //   child: Text(flex.toString()),
                // ),
                ));
          }),
        ),
        IconButton(onPressed: () => setState(() => children.length = 0), icon: const Icon(Icons.delete))
      ]),
      body: Column(
        children: [
          Flexbox(children: children),
          Expanded(child: LayoutBuilder(builder: (bc, cons) => Text(cons.maxWidth.toStringAsFixed(2))))
        ],
      ),
    );
  }
}
