import 'dart:core' as core;
import 'time/duration.dart';

extension StopwatchChronoExtension on core.Stopwatch {
  Microseconds get elapsedChrono => Microseconds(elapsedMicroseconds);
}
