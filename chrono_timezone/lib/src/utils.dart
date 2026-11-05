int? binarySearch(int length, int Function(int index) compare) {
  final result = binarySearchWithInsertionPoint(length, compare);
  return result.found ? result.index : null;
}

/// Like [binarySearch], but when nothing matches, [index] is the insertion
/// point, i.e., the index of the first element that compares greater.
({bool found, int index}) binarySearchWithInsertionPoint(
  int length,
  int Function(int index) compare,
) {
  var min = 0;
  var max = length;
  while (min < max) {
    final mid = min + ((max - min) >> 1);
    switch (compare(mid)) {
      case < 0:
        min = mid + 1;
      case 0:
        return (found: true, index: mid);
      case > 0:
        max = mid;
    }
  }
  return (found: false, index: min);
}
