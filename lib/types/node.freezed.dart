// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

part of 'node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$NodeTearOff {
  const _$NodeTearOff();

  _Node call(String t,
      {List<dynamic>? c, int? alignment, Map<String, String>? props}) {
    return _Node(
      t,
      c: c,
      alignment: alignment,
      props: props,
    );
  }
}

/// @nodoc
const $Node = _$NodeTearOff();

/// @nodoc
mixin _$Node {
  String get t => throw _privateConstructorUsedError;
  List<dynamic>? get c => throw _privateConstructorUsedError;
  int? get alignment => throw _privateConstructorUsedError;
  Map<String, String>? get props => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $NodeCopyWith<Node> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NodeCopyWith<$Res> {
  factory $NodeCopyWith(Node value, $Res Function(Node) then) =
      _$NodeCopyWithImpl<$Res>;
  $Res call(
      {String t, List<dynamic>? c, int? alignment, Map<String, String>? props});
}

/// @nodoc
class _$NodeCopyWithImpl<$Res> implements $NodeCopyWith<$Res> {
  _$NodeCopyWithImpl(this._value, this._then);

  final Node _value;
  // ignore: unused_field
  final $Res Function(Node) _then;

  @override
  $Res call({
    Object? t = freezed,
    Object? c = freezed,
    Object? alignment = freezed,
    Object? props = freezed,
  }) {
    return _then(_value.copyWith(
      t: t == freezed
          ? _value.t
          : t // ignore: cast_nullable_to_non_nullable
              as String,
      c: c == freezed
          ? _value.c
          : c // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      alignment: alignment == freezed
          ? _value.alignment
          : alignment // ignore: cast_nullable_to_non_nullable
              as int?,
      props: props == freezed
          ? _value.props
          : props // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
    ));
  }
}

/// @nodoc
abstract class _$NodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory _$NodeCopyWith(_Node value, $Res Function(_Node) then) =
      __$NodeCopyWithImpl<$Res>;
  @override
  $Res call(
      {String t, List<dynamic>? c, int? alignment, Map<String, String>? props});
}

/// @nodoc
class __$NodeCopyWithImpl<$Res> extends _$NodeCopyWithImpl<$Res>
    implements _$NodeCopyWith<$Res> {
  __$NodeCopyWithImpl(_Node _value, $Res Function(_Node) _then)
      : super(_value, (v) => _then(v as _Node));

  @override
  _Node get _value => super._value as _Node;

  @override
  $Res call({
    Object? t = freezed,
    Object? c = freezed,
    Object? alignment = freezed,
    Object? props = freezed,
  }) {
    return _then(_Node(
      t == freezed
          ? _value.t
          : t // ignore: cast_nullable_to_non_nullable
              as String,
      c: c == freezed
          ? _value.c
          : c // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      alignment: alignment == freezed
          ? _value.alignment
          : alignment // ignore: cast_nullable_to_non_nullable
              as int?,
      props: props == freezed
          ? _value.props
          : props // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
    ));
  }
}

/// @nodoc

class _$_Node extends _Node with DiagnosticableTreeMixin {
  _$_Node(this.t, {this.c, this.alignment, this.props}) : super._();

  @override
  final String t;
  @override
  final List<dynamic>? c;
  @override
  final int? alignment;
  @override
  final Map<String, String>? props;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Node(t: $t, c: $c, alignment: $alignment, props: $props)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Node'))
      ..add(DiagnosticsProperty('t', t))
      ..add(DiagnosticsProperty('c', c))
      ..add(DiagnosticsProperty('alignment', alignment))
      ..add(DiagnosticsProperty('props', props));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Node &&
            (identical(other.t, t) ||
                const DeepCollectionEquality().equals(other.t, t)) &&
            (identical(other.c, c) ||
                const DeepCollectionEquality().equals(other.c, c)) &&
            (identical(other.alignment, alignment) ||
                const DeepCollectionEquality()
                    .equals(other.alignment, alignment)) &&
            (identical(other.props, props) ||
                const DeepCollectionEquality().equals(other.props, props)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(t) ^
      const DeepCollectionEquality().hash(c) ^
      const DeepCollectionEquality().hash(alignment) ^
      const DeepCollectionEquality().hash(props);

  @JsonKey(ignore: true)
  @override
  _$NodeCopyWith<_Node> get copyWith =>
      __$NodeCopyWithImpl<_Node>(this, _$identity);
}

abstract class _Node extends Node {
  factory _Node(String t,
      {List<dynamic>? c, int? alignment, Map<String, String>? props}) = _$_Node;
  _Node._() : super._();

  @override
  String get t => throw _privateConstructorUsedError;
  @override
  List<dynamic>? get c => throw _privateConstructorUsedError;
  @override
  int? get alignment => throw _privateConstructorUsedError;
  @override
  Map<String, String>? get props => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$NodeCopyWith<_Node> get copyWith => throw _privateConstructorUsedError;
}
