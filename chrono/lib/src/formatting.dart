import 'package:cldr/cldr.dart';

abstract interface class Formatter<T extends Object> {
  String format(T value);
}

abstract class LocalizedFormatter<T extends Object> implements Formatter<T> {
  const LocalizedFormatter(this.localeData);

  final CommonLocaleData localeData;
}
