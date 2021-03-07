import 'dart:developer';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'types/Todo.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.compact,
      ),
      home: MyHomePage(title: 'YATA - Yet Another Todo App'),
    );
  }
}

class ListStore<T> extends StateNotifier<List<T>> {
  ListStore() : super([]);
  ListStore.seed(List<T> initState) : super(initState);

  void add(T t) => state = state..add(t);
  void clear() => state = state..length = 0;
  void insert(int idx, T t) => state = state..insert(idx, t);
  void removeAt(int idx) => state = state..removeAt(idx);
  void update(int idx, T mutator(T value)) {
    if (idx >= state.length) return;
    state = state..[idx] = mutator(state[idx]);
  }
}

final todos = StateNotifierProvider((_) => ListStore<Todo>());

class MyHomePage extends StatelessWidget {
  final String? title;
  MyHomePage({Key? key, this.title}) : super(key: key);

  build(bc) {
    return Scaffold(
      appBar: AppBar(title: Text(title!)),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => bc.read(todos).add(Todo()),
      ),
      body: Consumer(
        builder: (ctx, watch, child) {
          final store = watch(todos.state);
          if (store.length == 0 && child != null) return child;

          return ListView.builder(
            itemCount: store.length,
            itemBuilder: (_, i) {
              final todo = store[i];
              return TodoTile(todo, i, key: ObjectKey(todo.id));
            },
          );
        },
        child: Center(
          child: Text(
            "Let's do something!",
            style: Theme.of(bc).textTheme.headline4,
          ),
        ),
      ),
    );
  }
}

class TodoTile extends StatefulWidget {
  const TodoTile(this.todo, this.i, {Key? key}) : super(key: key);

  final Todo todo;
  final int i;

  @override
  _TodoTileState createState() => _TodoTileState();
}

class _TodoTileState extends State<TodoTile> {
  var editing = false;
  String? content;

  build(ctx) {
    final editor = TextFormField(
      maxLines: 2,
      minLines: 1,
      initialValue: widget.todo.content,
      onChanged: (val) => content = val,
      decoration: InputDecoration(
        hintText: "What to do next?",
        filled: true,
      ),
      onTap: () {
        ctx.read(todos).update(widget.i, (value) => value..content = content);
        setState(() => editing = false);
      },
    );

    final text = Text(
      widget.todo.content ?? "Nothing yet... (${widget.todo.id})",
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    return ListTile(
      title: editing ? editor : text,
      enabled: !editing,
      // onTap: () => setState(() => editing = true),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => setState(() => editing = true),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ctx.read(todos).insert(widget.i + 1, Todo()),
          ),
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () => ctx.read(todos).removeAt(widget.i),
          )
        ],
      ),
    );
  }
}
