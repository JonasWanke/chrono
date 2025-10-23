import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

@immutable
abstract class CodecAndJsonConverter<S extends Object, T> extends Codec<S, T>
    implements JsonConverter<S, T> {
  const CodecAndJsonConverter();

  @override
  Converter<S, T> get encoder => _FunctionBasedConverter(encode);
  @override
  Converter<T, S> get decoder => _FunctionBasedConverter(decode);

  @override
  T encode(S input);
  @override
  T toJson(S object) => encode(object);

  @override
  S decode(T encoded);
  @override
  S fromJson(T json) => decode(json);
}

class _FunctionBasedConverter<S, T> extends Converter<S, T> {
  const _FunctionBasedConverter(this._convert);

  final T Function(S) _convert;

  @override
  T convert(S input) => _convert(input);
}
