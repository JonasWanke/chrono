int? binarySearch(int length, int Function(int index) compare) {
  var min = 0;
  var max = length;
  while (min < max) {
    final mid = min + ((max - min) >> 1);
    switch (compare(mid)) {
      case < 0:
        min = mid + 1;
      case 0:
        return mid;
      case > 0:
        max = mid;
    }
  }
  return null;
}
