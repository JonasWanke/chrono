import 'package:supernova/supernova.dart';

import 'field.dart';

@immutable
class Line {
  const Line(this.lineIndex, this.fields);

  /// Original: `getfields`
  static Line parse(int lineIndex, String line) {
    var nextIndex = 0;
    int index() => nextIndex - 1;
    String? next() {
      final index = nextIndex++;
      if (index >= line.length) return null;
      return line[index];
    }

    final fields = <Field>[];
    void addField(String field) =>
        fields.add(Field(lineIndex, fields.length, field == '-' ? '' : field));

    loop:
    while (true) {
      String? character;
      switch (next()) {
        case null || '#':
          break loop;
        case final character when _isSpace(character):
          break;
        case '"':
          final start = index();
          do {
            character = next();
          } while (character != null && character != '"');
          if (character == null) {
            throw const FormatException('Odd number of quotation marks');
          }
          if (start + 2 == index()) {
            throw const FormatException('Empty field');
          }
          addField(line.substring(start + 1, index() - 1));
        default:
          // TODO: Compare handling for cases like `foo"bar…`
          final start = index();
          do {
            character = next();
          } while (
              character != null && character != '#' && !_isSpace(character));
          addField(line.substring(start, index()));
      }
    }
    return Line(lineIndex, fields);
  }

  static bool _isSpace(String character) {
    assert(character.length == 1);
    return switch (character) {
      ' ' || '\f' || '\t' || '\v' => true,
      _ => false,
    };
  }

  final int lineIndex;
  final List<Field> fields;

  void logError(String message) =>
      logger.error('Line $lineIndex: $message', fields);

  @override
  String toString() =>
      'Line $lineIndex: ${fields.map((it) => '“${it.value}”').joinToString()}';
}
