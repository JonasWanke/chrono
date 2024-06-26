import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
import 'utils.dart';

@immutable
abstract class JsonConverterWithParserResult<T extends Object, S>
    extends JsonConverter<T, S> {
  const JsonConverterWithParserResult();

  Result<T, FormatException> resultFromJson(S json);

  @override
  T fromJson(S json) => unwrapParserResult(resultFromJson(json));
}

@immutable
abstract class JsonConverterWithStringResult<T extends Object, S>
    extends JsonConverter<T, S> {
  const JsonConverterWithStringResult();

  Result<T, String> resultFromJson(S json);

  @override
  T fromJson(S json) => resultFromJson(json).unwrapOrThrowAsFormatException();
}
