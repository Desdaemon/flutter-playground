import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yata_flutter/widgets/common_app_bar.dart';

import '../state/todos.dart';
import '../types/todo.dart';

final klist = GlobalKey<AnimatedListState>();

Future<void> scrollToBottom({Duration? wait, Duration? animDur, Curve curve = Curves.easeInOut}) async {
  final sc = (klist.currentWidget as AnimatedList?)?.controller;
  if (sc != null && sc.hasClients) {
    if (wait != null) await Future.delayed(wait);
    if (animDur != null) {
      sc.animateTo(sc.position.maxScrollExtent, duration: animDur, curve: curve);
    } else {
      sc.jumpTo(sc.position.maxScrollExtent);
    }
  }
}

/// Group together transitions for this page.
Widget sizeFadeTransition({required Widget child, required Animation<double> anim, Key? key}) =>
    SizeTransition(key: key, sizeFactor: anim, child: FadeTransition(opacity: anim, child: child));

class TodoPage extends StatefulWidget {
  const TodoPage({Key? key, required this.title, this.duration = const Duration(milliseconds: 150)}) : super(key: key);
  final String title;
  final Duration duration;
  static const hint = "Let's do something! 💪︎";

  @override
  _TodoPageState createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  /// The cache for widgets whose index and content has not changed. If this
  /// screen only exists in the app once, it can be made static.
  final cache = <int, Widget?>{};
  final ctl = ScrollController();

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext bc) {
    return Scaffold(
      appBar: commonAppBar(bc, title: widget.title, actions: [
        IconButton(
          icon: const Icon(Icons.clear_all),
          onPressed: () => bc.read(todos).clear(),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final idx = bc.read(todos).add(Todo());
          klist.currentState?.insertItem(idx, duration: widget.duration);
          scrollToBottom(wait: widget.duration);
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Consumer(
          builder: (bc, watch, _) {
            // todoNotEmpty (a Provider<bool>) will only force an update when
            // the underlying state changes such that the == comparison fails.
            // (as of Riverpod v0.13.1)
            // For this reason, it is good practice to overload == for all
            // classes that you write.
            final isNotEmpty = watch(todoNotEmpty);
            return AnimatedSwitcher(
              duration: widget.duration,
              // A Visibility is used here,
              // but a simple ternary expression might suffice.
              child: Visibility(
                // The key here helps AnimatedSwitcher know that
                // this widget has changed.
                key: ValueKey(isNotEmpty),
                visible: isNotEmpty,
                replacement: Center(child: Text(TodoPage.hint, style: Theme.of(bc).textTheme.headline4)),
                child: Scrollbar(
                  child: AnimatedList(
                    key: klist,
                    controller: ctl,
                    // This is always 1, because when isNotEmpty updates
                    // the todo list is guaranteed to have finished
                    // adding its first element.
                    initialItemCount: 1,
                    itemBuilder: (bc, idx, anim) {
                      // itemBuilder is called for *every* index and/or length
                      // change. Therefore, a naïve implementation of a widget
                      // cache is used here to minimize updating work.
                      // This is optional.
                      var child = cache[idx] as TodoListItem?;
                      final thisTodo = bc.read(todos.state)[idx];
                      final changed = child?.idx != idx || child?.todo != thisTodo;
                      if (changed) {
                        child = TodoListItem(
                          idx,
                          thisTodo,
                          widget.duration,
                          key: ObjectKey(thisTodo),
                          autofocus: bc.read(todos).lastidx == idx,
                        );
                        cache[idx] = child;
                      }
                      return sizeFadeTransition(anim: anim, child: child!);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// This class is separate from [TodoTile], since we will need to provide
/// [AnimatedList] with a dummy corpse when we delete a todo. In other words,
/// this class defines the functionality, and [TodoTile] the look.
class TodoListItem extends StatefulWidget {
  const TodoListItem(this.idx, this.todo, this.duration, {Key? key, this.autofocus = false}) : super(key: key);
  final int idx;
  final Duration duration;
  final Todo todo;
  final bool autofocus;

  @override
  _TodoListItemState createState() => _TodoListItemState();
}

class _TodoListItemState extends State<TodoListItem> {
  int prevlen = 0;
  // bool editing = true;

  late Todo _todo;
  late TextEditingController ctl;
  late bool editing;
  final fn = FocusNode();

  @override
  void initState() {
    super.initState();
    _todo = widget.todo;
    editing = widget.autofocus;
    ctl = TextEditingController(text: _todo.content);
  }

  @override
  void dispose() {
    ctl.dispose();
    fn.dispose();
    super.dispose();
  }

  Todo get todo => _todo;

  /// Updates the store and triggers a [setState].
  set todo(Todo value) {
    context.read(todos).put(widget.idx, value);
    setState(() => _todo = value);
  }

  void doneEditing() {
    editing = false;
    todo = todo..content = ctl.text;
  }

  void insertTodo() {
    doneEditing();
    final idx = widget.idx + 1;
    context.read(todos).insert(idx, Todo());
    klist.currentState?.insertItem(idx, duration: widget.duration);
    scrollToBottom(wait: widget.duration);
  }

  void removeTodo() {
    klist.currentState?.removeItem(
      widget.idx,
      // Instead of passing a TodoListItem like in itemBuilder, we just need to
      // display a corpse for the duration of the animation.
      (_, anim) => sizeFadeTransition(
        // key: ValueKey(todo.id),
        anim: anim,
        child: TodoTile(todo: todo, dead: true),
      ),
      duration: widget.duration,
    );
    context.read(todos).removeAt(widget.idx);
  }

  /// Returns whether the event has been handled
  /// and should not propagate further.
  bool handleKey(RawKeyEvent event) {
    if (event.isKeyPressed(LogicalKeyboardKey.space) && ctl.text.length == prevlen /* Fixes a deviant space key */) {
      ctl.value = TextEditingValue(
        text: "${ctl.text} ",
        selection: TextSelection.collapsed(offset: ctl.selection.extentOffset + 1),
      );
      return true;
    } else if (event.isKeyPressed(LogicalKeyboardKey.enter) && !event.isAltPressed) {
      insertTodo();
      return true;
    } else if (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.backspace)) {
      final text = (ctl.text.split(" ")..length -= 1).join(" ");
      ctl.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
      return true;
    } else if (event.isKeyPressed(LogicalKeyboardKey.backspace) && ctl.text.isEmpty && prevlen == 0) {
      removeTodo();
      return true;
    } else if (event.isAltPressed && event.isKeyPressed(LogicalKeyboardKey.keyJ)) {
      todo = todo..done = !todo.done;
      return true;
    } else if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
      doneEditing();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext bc) {
    return FocusScope(
      // Handles some of the keypresses here, since some of them ended up being
      // passed to the ListTile down below, which is undesirable. Try removing
      // FocusScope and see what happens.
      onKey: (_, event) => handleKey(event),
      child: TodoTile(
        todo: todo,
        editing: editing,
        titleBuilder: (_) => TextField(
          autofocus: true,
          minLines: 1,
          maxLines: 2,
          controller: ctl,
          focusNode: fn,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration.collapsed(hintText: TodoTile.hint),
          onChanged: (val) => prevlen = ctl.text.length,
          onTap: doneEditing,
          onEditingComplete: insertTodo,
        ),
        onTap: () => setState(() => editing = true),
        onAdd: insertTodo,
        onChange: (val) {
          bc.read(todos).put(widget.idx, val);
          todo = val;
        },
        onDelete: removeTodo,
      ),
    );
  }
}

class TodoTile extends StatelessWidget {
  const TodoTile({
    Key? key,
    required Todo todo,
    this.titleBuilder,
    this.onTap,
    this.onAdd,
    void Function(Todo)? onChange,
    this.onDelete,
    this.dead = false,
    this.editing = false,
  })  : _todo = todo,
        _onChange = onChange,
        super(key: key);

  final Todo _todo;

  /// If true, returns a corpse of this title that can be passed
  /// as the argument to an [AnimatedList]'s `removeItem` method.
  final bool dead;

  /// If true, skips calling [titleBuilder] and returns
  /// a plain [Text] object for the title. Overridden by [dead].
  final bool editing;

  final void Function(Todo)? _onChange;
  final void Function()? onTap;
  final void Function()? onAdd;
  final void Function()? onDelete;

  /// Builds the title for the inner [ListTile], usually a [TextField].
  final Widget Function(BuildContext)? titleBuilder;

  static const hint = 'What to do next?';
  static void noop() {}

  Todo get todo => _todo;
  set todo(Todo todo) => _onChange?.call(todo);

  @override
  Widget build(BuildContext bc) {
    final isEmpty = todo.content?.isEmpty ?? true;
    return ListTile(
      title: !editing || dead
          ? Text(
              isEmpty ? hint : todo.content!,
              style: isEmpty ? TextStyle(color: Theme.of(bc).hintColor) : null,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : titleBuilder?.call(bc) ?? Container(),
      onTap: editing || dead ? null : onTap,
      leading: Checkbox(
        value: todo.done,
        onChanged: dead ? (_) {} : (val) => todo = todo..done = val!,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.add), onPressed: dead ? noop : onAdd),
          IconButton(icon: const Icon(Icons.done), onPressed: dead ? noop : onDelete),
        ],
      ),
    );
  }
}
