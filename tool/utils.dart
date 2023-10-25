import 'package:oxidized/oxidized.dart';

import 'field.dart';

extension ErrExtension<T extends Object> on Result<T, ParseException> {
  Err<R, ParseException> asErrorWithContext<R extends Object>(String context) =>
      Err(unwrapErr().withContext(context));
}
