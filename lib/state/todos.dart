import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yata_flutter/types/todo.dart';

class ListStore<T> extends StateNotifier<List<T>> {
  ListStore([List<T>? seed]) : super(seed ?? const []);

  int lastidx = 0;

  int add(T t) {
    lastidx = state.length;
    state = state..add(t);
    return lastidx;
  }

  void clear() {
    lastidx = 0;
    state = state..length = 0;
  }

  void insert(int idx, T t) {
    lastidx = idx;
    state = state..insert(idx, t);
  }

  void removeAt(int idx) {
    lastidx = idx;
    state = state..removeAt(idx);
  }

  void put(int idx, T t) => state = state..[idx] = t;

  T mutate(int idx, T Function(T) mutator) {
    final mutated = mutator(state[idx]);
    state = state..[idx] = mutated;
    return mutated;
  }
}

final todos = StateNotifierProvider<ListStore<Todo>, List<Todo>>((_) => ListStore());

/// Caches the non-empty state of [todos] here.
final todoNotEmpty = Provider((ref) => ref.watch(todos).isNotEmpty);
