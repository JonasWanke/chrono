import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

@immutable
abstract class const CodecAndJsonConverter<S extends Object, T>()
    extends Codec<S, T>
    implements JsonConverter<S, T> {
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

class const _FunctionBasedConverter<S, T>(final T Function(S) _convert)
    extends Converter<S, T> {
  @override
  T convert(S input) => _convert(input);
}
